part of 'phone_verification_bloc.dart';

enum PhoneVerificationStatus {
  /// Nothing has been asked for yet.
  initial,

  /// Waiting on `verify-phone/request`.
  sendingCode,

  /// A code is on its way to the number — step two can take over.
  codeSent,

  /// The number was already proved, so no code was sent and none is needed.
  alreadyVerified,

  /// Waiting on `verify-phone/confirm`.
  submittingCode,

  /// The code checked out; the account's number is now verified.
  verified,
}

class PhoneVerificationState extends Equatable {
  const PhoneVerificationState({
    this.status = PhoneVerificationStatus.initial,
    this.devCode,
    this.errorMessage,
    this.codeRejected = false,
  });

  final PhoneVerificationStatus status;

  /// The code the server echoed back, which only happens when it is running
  /// with mocked codes. Shown in debug builds so the flow can be walked
  /// without an SMS provider; null everywhere else.
  final String? devCode;

  /// Set for one emission after a failed call; the screen shows it and then
  /// dispatches [PhoneVerificationErrorDismissed].
  final String? errorMessage;

  /// True when the last failure was the code itself rather than the network
  /// or the server — the difference between painting the boxes red and
  /// showing a snackbar.
  final bool codeRejected;

  bool get isSendingCode => status == PhoneVerificationStatus.sendingCode;

  bool get isSubmittingCode => status == PhoneVerificationStatus.submittingCode;

  bool get isBusy => isSendingCode || isSubmittingCode;

  PhoneVerificationState copyWith({
    PhoneVerificationStatus? status,
    String? devCode,
    String? errorMessage,
    bool codeRejected = false,
  }) {
    return PhoneVerificationState(
      status: status ?? this.status,
      // Carried, unlike the message: a resend that fails should not blank out
      // the code the previous send handed back.
      devCode: devCode ?? this.devCode,
      // Not carried: a message is shown once, so anything that wants to keep
      // it has to pass it again.
      errorMessage: errorMessage,
      codeRejected: codeRejected,
    );
  }

  @override
  List<Object?> get props => [status, devCode, errorMessage, codeRejected];
}
