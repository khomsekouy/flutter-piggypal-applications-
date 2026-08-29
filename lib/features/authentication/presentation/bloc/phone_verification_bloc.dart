import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/error/failures.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/confirm_phone_verification.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/request_phone_verification.dart';

part 'phone_verification_event.dart';
part 'phone_verification_state.dart';

/// Drives the two verification screens: sending the code, and checking it.
///
/// Separate from `AuthenticationBloc` on purpose. That bloc's status *is* the
/// session — the splash screen and the router read it — and a code being
/// checked is not a session changing. What does change the session's view of
/// the world is success, and the screen reports that by dispatching
/// `AuthenticationUserRefreshed` so `AuthUser.phoneVerified` catches up.
///
/// One instance per screen: step one sends the first code, step two owns the
/// resends, and neither needs to know what the other did.
class PhoneVerificationBloc
    extends Bloc<PhoneVerificationEvent, PhoneVerificationState> {
  PhoneVerificationBloc({
    required RequestPhoneVerification requestPhoneVerification,
    required ConfirmPhoneVerification confirmPhoneVerification,
  }) : _requestCode = requestPhoneVerification,
       _confirmCode = confirmPhoneVerification,
       super(const PhoneVerificationState()) {
    on<PhoneVerificationCodeRequested>(_onCodeRequested);
    on<PhoneVerificationCodeSubmitted>(_onCodeSubmitted);
    on<PhoneVerificationErrorDismissed>(_onErrorDismissed);
  }

  final RequestPhoneVerification _requestCode;
  final ConfirmPhoneVerification _confirmCode;

  Future<void> _onCodeRequested(
    PhoneVerificationCodeRequested event,
    Emitter<PhoneVerificationState> emit,
  ) async {
    if (state.isBusy) return;

    // Where a failure leaves the user: back where they were standing. A
    // resend that the server refuses must not knock step two back to a state
    // that says no code was ever sent — the one in their messages still works.
    final settled = state.status == PhoneVerificationStatus.codeSent
        ? PhoneVerificationStatus.codeSent
        : PhoneVerificationStatus.initial;

    emit(state.copyWith(status: PhoneVerificationStatus.sendingCode));

    final result = await _requestCode(const NoParams());
    emit(
      result.match(
        (failure) => state.copyWith(
          status: settled,
          errorMessage: failure.message,
        ),
        (request) => state.copyWith(
          status: request.alreadyVerified
              ? PhoneVerificationStatus.alreadyVerified
              : PhoneVerificationStatus.codeSent,
          devCode: request.devCode,
        ),
      ),
    );
  }

  Future<void> _onCodeSubmitted(
    PhoneVerificationCodeSubmitted event,
    Emitter<PhoneVerificationState> emit,
  ) async {
    if (state.isBusy) return;
    emit(state.copyWith(status: PhoneVerificationStatus.submittingCode));

    final result = await _confirmCode(
      ConfirmPhoneVerificationParams(code: event.code),
    );
    emit(
      result.match(
        (failure) => state.copyWith(
          // Back to "a code is out there", because it still is — the user
          // gets to try the next five digits.
          status: PhoneVerificationStatus.codeSent,
          errorMessage: failure.message,
          // A wrong code belongs on the boxes; a dead connection does not.
          codeRejected: failure is VerificationFailure,
        ),
        (_) => state.copyWith(status: PhoneVerificationStatus.verified),
      ),
    );
  }

  /// Drops the message once the UI has shown it, so a rebuild cannot show the
  /// same snackbar twice.
  void _onErrorDismissed(
    PhoneVerificationErrorDismissed event,
    Emitter<PhoneVerificationState> emit,
  ) {
    if (state.errorMessage == null) return;
    emit(state.copyWith());
  }
}
