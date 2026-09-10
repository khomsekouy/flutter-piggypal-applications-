part of 'password_reset_bloc.dart';

enum PasswordResetStatus {
  /// Nothing has been asked for yet.
  initial,

  /// Waiting on `forgot-password`.
  sendingCode,

  /// The request was accepted. **Not** "a code was sent": the server answers
  /// an unknown number exactly as it answers a registered one, so this says
  /// only that the app may move on to the code screen.
  codeSent,

  /// Waiting on `verify-otp`.
  verifyingCode,

  /// The code checked out; [PasswordResetState.resetToken] is now set and the
  /// new-password screen can take over.
  codeVerified,

  /// Waiting on `reset-password`.
  updatingPassword,

  /// The password is changed and every session for the account is revoked.
  passwordUpdated,
}

class PasswordResetState extends Equatable {
  const PasswordResetState({
    this.status = PasswordResetStatus.initial,
    this.devCode,
    this.resetToken,
    this.errorMessage,
    this.codeRejected = false,
  });

  final PasswordResetStatus status;

  /// The code the server echoed back, which only happens when it is running
  /// with mocked codes *and* the number had an account. Shown in debug builds
  /// so the flow can be walked without an SMS provider; null everywhere else.
  final String? devCode;

  /// The ticket `verify-otp` minted, set once [status] reaches
  /// [PasswordResetStatus.codeVerified]. Ten minutes, one use.
  final String? resetToken;

  /// Set for one emission after a failed call; the screen shows it and then
  /// dispatches [PasswordResetErrorDismissed].
  final String? errorMessage;

  /// True when the last failure was the code or the reset token itself rather
  /// than the network or the server — the difference between painting the
  /// boxes red and showing a snackbar.
  final bool codeRejected;

  bool get isSendingCode => status == PasswordResetStatus.sendingCode;

  bool get isVerifyingCode => status == PasswordResetStatus.verifyingCode;

  bool get isUpdatingPassword =>
      status == PasswordResetStatus.updatingPassword;

  bool get isBusy => isSendingCode || isVerifyingCode || isUpdatingPassword;

  PasswordResetState copyWith({
    PasswordResetStatus? status,
    String? devCode,
    String? resetToken,
    String? errorMessage,
    bool codeRejected = false,
  }) {
    return PasswordResetState(
      status: status ?? this.status,
      // Carried, unlike the message: a resend that fails should not blank out
      // the code the previous send handed back.
      devCode: devCode ?? this.devCode,
      resetToken: resetToken ?? this.resetToken,
      // Not carried: a message is shown once, so anything that wants to keep
      // it has to pass it again.
      errorMessage: errorMessage,
      codeRejected: codeRejected,
    );
  }

  @override
  List<Object?> get props => [
    status,
    devCode,
    resetToken,
    errorMessage,
    codeRejected,
  ];
}
