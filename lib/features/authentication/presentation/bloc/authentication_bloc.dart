import 'dart:async';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/error/failures.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/entities/account_deletion.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/entities/auth_session.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/entities/auth_user.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/delete_account.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/get_current_user.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/restore_account.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/sign_in.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/sign_out.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/sign_up.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/update_profile_photo.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

/// Owns the session for the whole app.
///
/// Provided once above the router (see `app/view/app.dart`) rather than per
/// screen: sign-in creates the session, the More tab ends it, and the splash
/// screen asks whether there is one — three screens, one answer, so they have
/// to share an instance.
class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc({
    required SignIn signIn,
    required SignUp signUp,
    required SignOut signOut,
    required GetCurrentUser getCurrentUser,
    required UpdateProfilePhoto updateProfilePhoto,
    required DeleteAccount deleteAccount,
    required RestoreAccount restoreAccount,
    required AuthenticationRepository repository,
  }) : _signIn = signIn,
       _signUp = signUp,
       _signOut = signOut,
       _getCurrentUser = getCurrentUser,
       _updateProfilePhoto = updateProfilePhoto,
       _deleteAccount = deleteAccount,
       _restoreAccount = restoreAccount,
       _repository = repository,
       super(const AuthenticationState()) {
    on<AuthenticationStarted>(_onStarted);
    on<AuthenticationSignInRequested>(_onSignInRequested);
    on<AuthenticationSignUpRequested>(_onSignUpRequested);
    on<AuthenticationProfilePhotoUpdated>(_onProfilePhotoUpdated);
    on<AuthenticationSignOutRequested>(_onSignOutRequested);
    on<AuthenticationDeleteAccountRequested>(_onDeleteAccountRequested);
    on<AuthenticationAccountRestoreRequested>(_onAccountRestoreRequested);
    on<AuthenticationUserRefreshed>(_onUserRefreshed);
    on<AuthenticationErrorDismissed>(_onErrorDismissed);
    on<AuthenticationNoticeDismissed>(_onNoticeDismissed);
    on<AuthenticationSessionExpired>(_onSessionExpired);

    // Expiry arrives from the network layer, not from anything the user did:
    // requests refresh and retry themselves, and only a refresh token the
    // server rejects gets this far.
    _expirySubscription = _repository.sessionExpired.listen(
      (_) => add(const AuthenticationSessionExpired()),
    );
  }

  final SignIn _signIn;
  final SignUp _signUp;
  final SignOut _signOut;
  final GetCurrentUser _getCurrentUser;
  final UpdateProfilePhoto _updateProfilePhoto;
  final DeleteAccount _deleteAccount;
  final RestoreAccount _restoreAccount;

  /// For `hasSession()` — the cheap "is there a token on disk" check, which is
  /// not worth a use case of its own — and for the expiry stream.
  final AuthenticationRepository _repository;

  late final StreamSubscription<void> _expirySubscription;

  /// Launch check: a stored token is only a hint, so it is confirmed against
  /// `GET /users/me` before the user is treated as signed in.
  Future<void> _onStarted(
    AuthenticationStarted event,
    Emitter<AuthenticationState> emit,
  ) async {
    if (!await _repository.hasSession()) {
      emit(state.copyWith(status: AuthenticationStatus.unauthenticated));
      return;
    }

    emit(state.copyWith(status: AuthenticationStatus.loading));
    final result = await _getCurrentUser(const NoParams());
    emit(
      result.match(
        // The launch check itself stays quiet — a rejected token just means
        // "sign in again". Any message already on the state was put there by
        // the network layer (a refresh that came back rejected) and is worth
        // more than this, so it is carried rather than cleared.
        (failure) => state.copyWith(
          status: AuthenticationStatus.unauthenticated,
          clearUser: true,
          errorMessage: state.errorMessage,
        ),
        (user) => state.copyWith(
          status: AuthenticationStatus.authenticated,
          user: user,
        ),
      ),
    );
  }

  Future<void> _onSignInRequested(
    AuthenticationSignInRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(state.copyWith(status: AuthenticationStatus.loading));
    final result = await _signIn(
      SignInParams(
        countryCode: event.countryCode,
        phone: event.phone,
        password: event.password,
      ),
    );
    await _emitSession(result, emit);
  }

  Future<void> _onSignUpRequested(
    AuthenticationSignUpRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(state.copyWith(status: AuthenticationStatus.loading));
    final result = await _signUp(
      SignUpParams(
        countryCode: event.countryCode,
        phone: event.phone,
        password: event.password,
        email: event.email,
        name: event.name,
      ),
    );
    await _emitSession(result, emit);
  }

  /// Unlike the other calls here, a failure leaves the session alone: the
  /// account is made and signed in, and a picture that would not upload is
  /// worth a message, not a sign-out.
  Future<void> _onProfilePhotoUpdated(
    AuthenticationProfilePhotoUpdated event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(state.copyWith(status: AuthenticationStatus.loading));
    final result = await _updateProfilePhoto(
      UpdateProfilePhotoParams(
        avatar: event.avatar,
        avatarFileName: event.avatarFileName,
      ),
    );
    emit(
      result.match(
        (failure) => state.copyWith(
          status: AuthenticationStatus.authenticated,
          errorMessage: failure.message,
        ),
        (user) => state.copyWith(
          status: AuthenticationStatus.authenticated,
          user: user,
        ),
      ),
    );
  }

  Future<void> _onSignOutRequested(
    AuthenticationSignOutRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    final result = await _signOut(const NoParams());
    // Unauthenticated either way: the repository clears the local tokens even
    // when the server call fails, so there is no session left to claim.
    emit(
      state.copyWith(
        status: AuthenticationStatus.unauthenticated,
        clearUser: true,
        errorMessage: result.match<String?>(
          (failure) => failure.message,
          (_) => null,
        ),
      ),
    );
  }

  /// Re-reads the profile — after an edit, or when a cached copy is stale.
  Future<void> _onUserRefreshed(
    AuthenticationUserRefreshed event,
    Emitter<AuthenticationState> emit,
  ) async {
    final result = await _getCurrentUser(const NoParams());
    emit(
      result.match(
        (failure) => failure is AuthFailure
            ? state.copyWith(
                status: AuthenticationStatus.unauthenticated,
                clearUser: true,
                errorMessage: state.errorMessage,
              )
            : state.copyWith(errorMessage: failure.message),
        (user) => state.copyWith(
          status: AuthenticationStatus.authenticated,
          user: user,
        ),
      ),
    );
  }

  /// The session ended while the app was in use. Says so, because unlike
  /// every other route to `unauthenticated` the user did not ask for this and
  /// is about to find themselves back on sign-in.
  void _onSessionExpired(
    AuthenticationSessionExpired event,
    Emitter<AuthenticationState> emit,
  ) {
    emit(
      state.copyWith(
        status: AuthenticationStatus.unauthenticated,
        clearUser: true,
        errorMessage: 'Your session has expired. Please sign in again.',
      ),
    );
  }

  /// Ends the session by destroying the account behind it.
  ///
  /// A failure here is almost always a mistyped password, and leaves the user
  /// exactly where they were: still signed in, with the message. Only success
  /// signs them out — and it carries the recovery window with it, because the
  /// screen that can show that has not been built yet when this runs.
  Future<void> _onDeleteAccountRequested(
    AuthenticationDeleteAccountRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(state.copyWith(status: AuthenticationStatus.loading));
    final result = await _deleteAccount(
      DeleteAccountParams(password: event.password),
    );
    emit(
      result.match(
        (failure) => state.copyWith(
          status: AuthenticationStatus.authenticated,
          errorMessage: failure.message,
        ),
        (deletion) => state.copyWith(
          status: AuthenticationStatus.unauthenticated,
          clearUser: true,
          notice: _recoveryNotice(deletion),
        ),
      ),
    );
  }

  /// The same shape as signing in, because that is what it is: the account
  /// comes back and the response carries a session.
  Future<void> _onAccountRestoreRequested(
    AuthenticationAccountRestoreRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(state.copyWith(status: AuthenticationStatus.loading));
    final result = await _restoreAccount(
      RestoreAccountParams(
        countryCode: event.countryCode,
        phone: event.phone,
        password: event.password,
      ),
    );
    await _emitSession(result, emit);
  }

  /// What the user is told once the deletion has landed and they are back on
  /// the sign-in screen.
  ///
  /// A date the server did not send is left unsaid rather than guessed at: the
  /// grace period is configured server-side, so a "30 days" invented here
  /// would be the app promising something it does not know.
  String _recoveryNotice(AccountDeletion deletion) {
    final purgeAt = deletion.purgeAt;
    const lead = 'Your account is scheduled for deletion.';

    return purgeAt == null
        ? '$lead You can still recover it by signing in again below.'
        : '$lead You can recover it until '
              '${DateFormat.yMMMMd().format(purgeAt)}.';
  }

  /// Drops the message once the UI has shown it, so a rebuild cannot show the
  /// same snackbar twice.
  void _onErrorDismissed(
    AuthenticationErrorDismissed event,
    Emitter<AuthenticationState> emit,
  ) {
    if (state.errorMessage == null) return;
    emit(state.copyWith());
  }

  /// As [_onErrorDismissed], for the notice that outlives the screen that set
  /// it.
  void _onNoticeDismissed(
    AuthenticationNoticeDismissed event,
    Emitter<AuthenticationState> emit,
  ) {
    if (state.notice == null) return;
    emit(state.copyWith(clearNotice: true));
  }

  @override
  Future<void> close() {
    unawaited(_expirySubscription.cancel());
    return super.close();
  }

  /// Emits the new session, then fills in the half of the profile it does not
  /// carry.
  ///
  /// `POST /auth/login` and `POST /auth/register` answer with the API's
  /// `publicUser`: id, phone, email, name, avatarUrl, and nothing else. The
  /// five fields left out — `currency`, `status`, `phoneVerified`,
  /// `emailVerified`, `createdAt` — do not arrive as "unknown" but as `null`
  /// and `false`, which reads as an unverified account that joined on no date.
  /// That is why a fresh sign-in used to leave the account screen showing its
  /// placeholder join date until the next launch, where
  /// [AuthenticationStarted] reads `GET /users/me` and silently corrects it.
  ///
  /// So the profile is read here as well, and the session is emitted first and
  /// kept whatever that read does: the tokens are already stored and the
  /// account is signed in, so a profile that will not load is a thinner
  /// screen, never a reason to send the user back to sign-in.
  Future<void> _emitSession(
    Either<Failure, AuthSession> result,
    Emitter<AuthenticationState> emit,
  ) async {
    final session = _sessionOutcome(result);
    emit(session);
    if (session.status != AuthenticationStatus.authenticated) return;

    final profile = await _getCurrentUser(const NoParams());
    // Closed while the profile was in flight — nothing left to emit into.
    if (emit.isDone) return;

    final user = profile.toNullable();
    if (user != null) emit(state.copyWith(user: user));
  }

  AuthenticationState _sessionOutcome(
    Either<Failure, AuthSession> result,
  ) => result.match(
    (failure) => state.copyWith(
      status: AuthenticationStatus.unauthenticated,
      clearUser: true,
      errorMessage: failure.message,
    ),
    (session) => state.copyWith(
      status: AuthenticationStatus.authenticated,
      user: session.user,
    ),
  );
}
