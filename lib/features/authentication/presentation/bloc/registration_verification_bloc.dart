import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/error/failures.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/request_registration_code.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/verify_registration_code.dart';

part 'registration_verification_event.dart';
part 'registration_verification_state.dart';

/// Proves a number *before* the account exists — the first two of the three
/// calls sign-up makes.
///
/// Separate from `PhoneVerificationBloc`, which cannot do this job: that one
/// answers to `verify-phone/request`, which reads the number off the caller's
/// access token and so needs an account to already be there. These two calls
/// are unguarded and carry the number in the body, because at this point in
/// the flow there is nothing else to identify it with.
///
/// Separate from `AuthenticationBloc` for the reason that bloc's own status
/// *is* the session, and a code being checked is not a session changing. What
/// this hands over — [RegistrationVerificationState.token] — is what the
/// sign-up screen sends with `register`, which is the request that does change
/// the session.
class RegistrationVerificationBloc
    extends
        Bloc<RegistrationVerificationEvent, RegistrationVerificationState> {
  RegistrationVerificationBloc({
    required RequestRegistrationCode requestRegistrationCode,
    required VerifyRegistrationCode verifyRegistrationCode,
  }) : _requestCode = requestRegistrationCode,
       _verifyCode = verifyRegistrationCode,
       super(const RegistrationVerificationState()) {
    on<RegistrationCodeRequested>(_onCodeRequested);
    on<RegistrationCodeSubmitted>(_onCodeSubmitted);
    on<RegistrationVerificationInvalidated>(_onInvalidated);
    on<RegistrationVerificationErrorDismissed>(_onErrorDismissed);
  }

  final RequestRegistrationCode _requestCode;
  final VerifyRegistrationCode _verifyCode;

  Future<void> _onCodeRequested(
    RegistrationCodeRequested event,
    Emitter<RegistrationVerificationState> emit,
  ) async {
    if (state.isBusy) return;

    // Where a failure leaves the user: back where they were standing. A
    // resend the server refuses must not knock the code pane back to a state
    // that says no code was ever sent — the one in their messages still works.
    final settled = state.status == RegistrationVerificationStatus.codeSent
        ? RegistrationVerificationStatus.codeSent
        : RegistrationVerificationStatus.initial;

    emit(
      state.copyWith(status: RegistrationVerificationStatus.sendingCode),
    );

    final result = await _requestCode(
      RequestRegistrationCodeParams(
        countryCode: event.countryCode,
        phone: event.phone,
      ),
    );
    emit(
      result.match(
        (failure) => state.copyWith(
          status: settled,
          errorMessage: failure.message,
          // A number that already has an account is a fact about the *number*,
          // so the screen puts it on the field the user can act on rather than
          // in a message that slides away.
          numberRejected: _isConflict(failure),
        ),
        (request) => state.copyWith(
          status: RegistrationVerificationStatus.codeSent,
          phone: event.phone,
          devCode: request.devCode,
        ),
      ),
    );
  }

  Future<void> _onCodeSubmitted(
    RegistrationCodeSubmitted event,
    Emitter<RegistrationVerificationState> emit,
  ) async {
    if (state.isBusy) return;
    emit(
      state.copyWith(status: RegistrationVerificationStatus.verifyingCode),
    );

    final result = await _verifyCode(
      VerifyRegistrationCodeParams(
        countryCode: event.countryCode,
        phone: event.phone,
        code: event.code,
      ),
    );
    emit(
      result.match(
        (failure) => state.copyWith(
          // Back to "a code is out there", because it still is — the user gets
          // to try the digits again, up to the five the server allows.
          status: RegistrationVerificationStatus.codeSent,
          errorMessage: failure.message,
          // A wrong code belongs on the boxes; a dead connection does not.
          codeRejected: failure is VerificationFailure,
          // The number could have been claimed between the two calls, which
          // the server answers with the same 409 step one gives.
          numberRejected: _isConflict(failure),
        ),
        (verification) => state.copyWith(
          status: RegistrationVerificationStatus.verified,
          phone: event.phone,
          token: verification.token,
        ),
      ),
    );
  }

  /// The proof did not survive to the end of sign-up — `register` refused it
  /// as expired or already spent, or the user went back and changed the
  /// number it was issued for. Either way there is nothing left to send, and
  /// the only way on is another code.
  void _onInvalidated(
    RegistrationVerificationInvalidated event,
    Emitter<RegistrationVerificationState> emit,
  ) {
    if (state.status == RegistrationVerificationStatus.initial) return;
    emit(const RegistrationVerificationState());
  }

  /// Drops the message once the UI has shown it, so a rebuild cannot show the
  /// same snackbar twice.
  void _onErrorDismissed(
    RegistrationVerificationErrorDismissed event,
    Emitter<RegistrationVerificationState> emit,
  ) {
    if (state.errorMessage == null) return;
    emit(state.copyWith());
  }

  /// A 409 — the number is registered already. Read off the status rather than
  /// the wording, which is the server's to change.
  bool _isConflict(Failure failure) =>
      failure is ServerFailure && failure.statusCode == 409;
}
