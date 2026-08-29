part of 'phone_verification_bloc.dart';

sealed class PhoneVerificationEvent extends Equatable {
  const PhoneVerificationEvent();

  @override
  List<Object?> get props => [];
}

/// `POST /auth/verify-phone/request`. Doubles as the resend: the server
/// retires whatever code was live and issues a new one either way.
class PhoneVerificationCodeRequested extends PhoneVerificationEvent {
  const PhoneVerificationCodeRequested();
}

/// `POST /auth/verify-phone/confirm` with the six digits the user typed.
class PhoneVerificationCodeSubmitted extends PhoneVerificationEvent {
  const PhoneVerificationCodeSubmitted(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}

/// The UI has shown [PhoneVerificationState.errorMessage]; clear it.
class PhoneVerificationErrorDismissed extends PhoneVerificationEvent {
  const PhoneVerificationErrorDismissed();
}
