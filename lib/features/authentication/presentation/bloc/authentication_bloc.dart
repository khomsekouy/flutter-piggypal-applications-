import 'dart:async';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/error/failures.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/entities/auth_session.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/entities/auth_user.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/get_current_user.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/sign_in.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/sign_out.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/sign_up.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/update_profile_photo.dart';
import 'package:fpdart/fpdart.dart';

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
    required AuthenticationRepository repository,
  }) : _signIn = signIn,
       _signUp = signUp,
       _signOut = signOut,
       _getCurrentUser = getCurrentUser,
       _updateProfilePhoto = updateProfilePhoto,
       _repository = repository,
       super(const AuthenticationState()) {
    on<AuthenticationStarted>(_onStarted);
    on<AuthenticationSignInRequested>(_onSignInRequested);
    on<AuthenticationSignUpRequested>(_onSignUpRequested);
    on<AuthenticationProfilePhotoUpdated>(_onProfilePhotoUpdated);
    on<AuthenticationSignOutRequested>(_onSignOutRequested);
    on<AuthenticationUserRefreshed>(_onUserRefreshed);
    on<AuthenticationErrorDismissed>(_onErrorDismissed);
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
    emit(_sessionOutcome(result));
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
    emit(_sessionOutcome(result));
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

  /// Drops the message once the UI has shown it, so a rebuild cannot show the
  /// same snackbar twice.
  void _onErrorDismissed(
    AuthenticationErrorDismissed event,
    Emitter<AuthenticationState> emit,
  ) {
    if (state.errorMessage == null) return;
    emit(state.copyWith());
  }

  @override
  Future<void> close() {
    unawaited(_expirySubscription.cancel());
    return super.close();
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
