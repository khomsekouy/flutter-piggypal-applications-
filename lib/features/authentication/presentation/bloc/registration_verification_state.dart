part of 'registration_verification_bloc.dart';

enum RegistrationVerificationStatus {
  /// Nothing has been asked for yet.
  initial,

  /// Waiting on `register/request-otp`.
  sendingCode,

  /// A code is on its way to the number — the boxes can take over.
  codeSent,

  /// Waiting on `register/verify-otp`.
  verifyingCode,

  /// The code checked out and [RegistrationVerificationState.token] holds the
  /// proof. No account yet: that is the request after this one.
  verified,
}

class RegistrationVerificationState extends Equatable {
  const RegistrationVerificationState({
    this.status = RegistrationVerificationStatus.initial,
    this.phone,
    this.token,
    this.devCode,
    this.errorMessage,
    this.codeRejected = false,
    this.numberRejected = false,
  });

  final RegistrationVerificationStatus status;

  /// The national number the last code was sent to, and — once [token] is
  /// here — the number that token proves. Kept so the screen can tell whether
  /// the number in the form is still the one that was verified: edit a digit
  /// and the proof no longer applies to it.
  final String? phone;

  /// Proof that [phone] answered its code, to be sent with `register`. Good
  /// for ten minutes and one use.
  final String? token;

  /// The code the server echoed back, which only happens when it is running
  /// with mocked codes. Shown in debug builds so the flow can be walked
  /// without an SMS provider; null everywhere else.
  final String? devCode;

  /// Set for one emission after a failed call; the screen shows it and then
  /// dispatches [RegistrationVerificationErrorDismissed].
  final String? errorMessage;

  /// True when the last failure was the six digits rather than the network or
  /// the server — the difference between painting the boxes red and showing a
  /// snackbar.
  final bool codeRejected;

  /// True when the last failure was the number already having an account. The
  /// screen sends the user back to the field rather than leaving them at six
  /// boxes no code will ever arrive for.
  final bool numberRejected;

  bool get isSendingCode =>
      status == RegistrationVerificationStatus.sendingCode;

  bool get isVerifyingCode =>
      status == RegistrationVerificationStatus.verifyingCode;

  bool get isBusy => isSendingCode || isVerifyingCode;

  bool get isVerified => status == RegistrationVerificationStatus.verified;

  /// Whether [number] is the one [token] proves. False for anything else,
  /// including a number that only got as far as being texted.
  bool provesNumber(String number) =>
      isVerified && token != null && phone == number;

  RegistrationVerificationState copyWith({
    RegistrationVerificationStatus? status,
    String? phone,
    String? token,
    String? devCode,
    String? errorMessage,
    bool codeRejected = false,
    bool numberRejected = false,
  }) {
    return RegistrationVerificationState(
      status: status ?? this.status,
      phone: phone ?? this.phone,
      token: token ?? this.token,
      // Carried, unlike the message: a resend that fails should not blank out
      // the code the previous send handed back.
      devCode: devCode ?? this.devCode,
      // Not carried: a message is shown once, so anything that wants to keep
      // it has to pass it again.
      errorMessage: errorMessage,
      codeRejected: codeRejected,
      numberRejected: numberRejected,
    );
  }

  @override
  List<Object?> get props => [
    status,
    phone,
    token,
    devCode,
    errorMessage,
    codeRejected,
    numberRejected,
  ];
}
