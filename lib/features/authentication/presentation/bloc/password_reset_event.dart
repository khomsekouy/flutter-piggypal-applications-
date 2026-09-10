part of 'password_reset_bloc.dart';

sealed class PasswordResetEvent extends Equatable {
  const PasswordResetEvent();

  @override
  List<Object?> get props => [];
}

/// `POST /auth/forgot-password`. Doubles as the resend: the server retires
/// whatever code was live and issues a new one either way.
///
/// Carries the number because there is no session to read one from — every
/// step of this flow is unguarded by necessity.
class PasswordResetCodeRequested extends PasswordResetEvent {
  const PasswordResetCodeRequested({
    required this.countryCode,
    required this.phone,
  });

  /// The dialling code (`+855`).
  final String countryCode;

  /// The **national** number only (`12345678`).
  final String phone;

  @override
  List<Object?> get props => [countryCode, phone];
}

/// `POST /auth/verify-otp` with the six digits the user typed.
class PasswordResetCodeSubmitted extends PasswordResetEvent {
  const PasswordResetCodeSubmitted({
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

/// `POST /auth/reset-password` with the token the previous step returned.
///
/// The token is passed in rather than read from the state: the new-password
/// screen is a separate route with its own bloc, and the token reaches it
/// through the navigation rather than through this one.
class PasswordResetSubmitted extends PasswordResetEvent {
  const PasswordResetSubmitted({
    required this.resetToken,
    required this.newPassword,
  });

  final String resetToken;
  final String newPassword;

  @override
  List<Object?> get props => [resetToken, newPassword];
}

/// The UI has shown [PasswordResetState.errorMessage]; clear it.
class PasswordResetErrorDismissed extends PasswordResetEvent {
  const PasswordResetErrorDismissed();
}
