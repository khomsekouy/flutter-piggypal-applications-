part of 'authentication_bloc.dart';

sealed class AuthenticationEvent extends Equatable {
  const AuthenticationEvent();

  @override
  List<Object?> get props => [];
}

/// Resolve the session at launch: is there a stored token, and does the server
/// still accept it?
class AuthenticationStarted extends AuthenticationEvent {
  const AuthenticationStarted();
}

/// `POST /auth/login`. [phone] is the national number only — the dialling code
/// travels separately in [countryCode], which is how the API wants it.
class AuthenticationSignInRequested extends AuthenticationEvent {
  const AuthenticationSignInRequested({
    required this.countryCode,
    required this.phone,
    required this.password,
  });

  final String countryCode;
  final String phone;
  final String password;

  @override
  List<Object?> get props => [countryCode, phone, password];
}

/// `POST /auth/register`. [avatar] is optional and uploaded with the account.
class AuthenticationSignUpRequested extends AuthenticationEvent {
  const AuthenticationSignUpRequested({
    required this.countryCode,
    required this.phone,
    required this.password,
    this.email,
    this.name,
    this.avatar,
    this.avatarFileName,
  });

  final String countryCode;
  final String phone;
  final String password;
  final String? email;
  final String? name;
  final Uint8List? avatar;
  final String? avatarFileName;

  @override
  List<Object?> get props => [
    countryCode,
    phone,
    password,
    email,
    name,
    avatar,
    avatarFileName,
  ];
}

/// `POST /auth/logout`, then forget the tokens.
class AuthenticationSignOutRequested extends AuthenticationEvent {
  const AuthenticationSignOutRequested();
}

/// Re-read `GET /users/me`.
class AuthenticationUserRefreshed extends AuthenticationEvent {
  const AuthenticationUserRefreshed();
}

/// The refresh token was rejected, so the session is over — raised by the
/// network layer rather than by a screen.
class AuthenticationSessionExpired extends AuthenticationEvent {
  const AuthenticationSessionExpired();
}

/// The UI has shown [AuthenticationState.errorMessage]; clear it.
class AuthenticationErrorDismissed extends AuthenticationEvent {
  const AuthenticationErrorDismissed();
}
