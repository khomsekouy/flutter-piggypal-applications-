part of 'registration_verification_bloc.dart';

sealed class RegistrationVerificationEvent extends Equatable {
  const RegistrationVerificationEvent();

  @override
  List<Object?> get props => [];
}

/// `POST /auth/register/request-otp`. Doubles as the resend: the server
/// retires whatever code was live for the number and issues a new one either
/// way.
class RegistrationCodeRequested extends RegistrationVerificationEvent {
  const RegistrationCodeRequested({
    required this.countryCode,
    required this.phone,
  });

  final String countryCode;

  /// National number only — the dialling code travels beside it, which is how
  /// the API wants the two.
  final String phone;

  @override
  List<Object?> get props => [countryCode, phone];
}

/// `POST /auth/register/verify-otp` with the six digits the user typed.
class RegistrationCodeSubmitted extends RegistrationVerificationEvent {
  const RegistrationCodeSubmitted({
    required this.countryCode,
    required this.phone,
    required this.code,
  });

  final String countryCode;
  final String phone;
  final String code;

  @override
  List<Object?> get props => [countryCode, phone, code];
}

/// Throw away the proof: `register` refused it, or the number it was issued
/// for has been edited. Puts the flow back to "no code has been sent".
class RegistrationVerificationInvalidated
    extends RegistrationVerificationEvent {
  const RegistrationVerificationInvalidated();
}

/// The UI has shown [RegistrationVerificationState.errorMessage]; clear it.
class RegistrationVerificationErrorDismissed
    extends RegistrationVerificationEvent {
  const RegistrationVerificationErrorDismissed();
}
