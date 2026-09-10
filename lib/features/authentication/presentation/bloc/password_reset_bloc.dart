import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/error/failures.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/request_password_reset.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/reset_password.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/verify_password_reset_code.dart';

part 'password_reset_event.dart';
part 'password_reset_state.dart';

/// Drives the three screens of the password reset: the number, the code, and
/// the new password.
///
/// Separate from `AuthenticationBloc` for the same reason
/// `PhoneVerificationBloc` is — none of this is a session changing. It is in
/// fact the opposite: the flow exists precisely because the user has no
/// session and cannot get one, and finishing it revokes any that were left.
///
/// One instance per screen, so each of the three steps owns its own loading
/// and error state. What has to survive the jump between them travels through
/// the navigation instead: the number as query parameters, and the reset
/// token as the route's `extra`. That keeps the token out of both the URL and
/// any store — it is a credential with a ten-minute life, and nothing should
/// outlive the screens that use it.
class PasswordResetBloc extends Bloc<PasswordResetEvent, PasswordResetState> {
  PasswordResetBloc({
    required RequestPasswordReset requestPasswordReset,
    required VerifyPasswordResetCode verifyPasswordResetCode,
    required ResetPassword resetPassword,
  }) : _requestCode = requestPasswordReset,
       _verifyCode = verifyPasswordResetCode,
       _resetPassword = resetPassword,
       super(const PasswordResetState()) {
    on<PasswordResetCodeRequested>(_onCodeRequested);
    on<PasswordResetCodeSubmitted>(_onCodeSubmitted);
    on<PasswordResetSubmitted>(_onPasswordSubmitted);
    on<PasswordResetErrorDismissed>(_onErrorDismissed);
  }

  final RequestPasswordReset _requestCode;
  final VerifyPasswordResetCode _verifyCode;
  final ResetPassword _resetPassword;

  Future<void> _onCodeRequested(
    PasswordResetCodeRequested event,
    Emitter<PasswordResetState> emit,
  ) async {
    if (state.isBusy) return;

    // Where a failure leaves the user: back where they were standing. A
    // resend the server refuses — the fourth inside fifteen minutes is
    // throttled — must not knock the code screen back to a state that says
    // nothing was ever sent, because the code in their messages still works.
    final settled = state.status == PasswordResetStatus.codeSent
        ? PasswordResetStatus.codeSent
        : PasswordResetStatus.initial;

    emit(state.copyWith(status: PasswordResetStatus.sendingCode));

    final result = await _requestCode(
      RequestPasswordResetParams(
        countryCode: event.countryCode,
        phone: event.phone,
      ),
    );
    emit(
      result.match(
        (failure) => state.copyWith(
          status: settled,
          errorMessage: failure.message,
        ),
        // Success says nothing about whether the number is registered, and
        // must not: the server answers both cases identically so that this
        // screen cannot be used to find out which numbers have accounts.
        (request) => state.copyWith(
          status: PasswordResetStatus.codeSent,
          devCode: request.devCode,
        ),
      ),
    );
  }

  Future<void> _onCodeSubmitted(
    PasswordResetCodeSubmitted event,
    Emitter<PasswordResetState> emit,
  ) async {
    if (state.isBusy) return;
    emit(state.copyWith(status: PasswordResetStatus.verifyingCode));

    final result = await _verifyCode(
      VerifyPasswordResetCodeParams(
        countryCode: event.countryCode,
        phone: event.phone,
        code: event.code,
      ),
    );
    emit(
      result.match(
        (failure) => state.copyWith(
          // Back to "a code is out there", because it still is — the user
          // gets to try the remaining guesses of the five they are allowed.
          status: PasswordResetStatus.codeSent,
          errorMessage: failure.message,
          // A wrong code belongs on the boxes; a dead connection does not.
          codeRejected: failure is VerificationFailure,
        ),
        (token) => state.copyWith(
          status: PasswordResetStatus.codeVerified,
          resetToken: token.token,
        ),
      ),
    );
  }

  Future<void> _onPasswordSubmitted(
    PasswordResetSubmitted event,
    Emitter<PasswordResetState> emit,
  ) async {
    if (state.isBusy) return;
    emit(state.copyWith(status: PasswordResetStatus.updatingPassword));

    final result = await _resetPassword(
      ResetPasswordParams(
        resetToken: event.resetToken,
        newPassword: event.newPassword,
      ),
    );
    emit(
      result.match(
        (failure) => state.copyWith(
          status: PasswordResetStatus.initial,
          errorMessage: failure.message,
          // A rejected token here means the ten minutes ran out or it was
          // already spent. The screen reads this as "send them back to the
          // start", since there is nothing left on this one that can succeed.
          codeRejected: failure is VerificationFailure,
        ),
        (_) => state.copyWith(status: PasswordResetStatus.passwordUpdated),
      ),
    );
  }

  /// Drops the message once the UI has shown it, so a rebuild cannot show the
  /// same snackbar twice.
  void _onErrorDismissed(
    PasswordResetErrorDismissed event,
    Emitter<PasswordResetState> emit,
  ) {
    if (state.errorMessage == null) return;
    emit(state.copyWith());
  }
}
