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

/// `POST /auth/register`, which also signs the new account in.
///
/// No picture here any more: it is picked on the last screen of sign-up, by
/// which point the account exists and there is no registration request left
/// to attach it to. See [AuthenticationProfilePhotoUpdated].
class AuthenticationSignUpRequested extends AuthenticationEvent {
  const AuthenticationSignUpRequested({
    required this.countryCode,
    required this.phone,
    required this.password,
    this.email,
    this.name,
  });

  final String countryCode;
  final String phone;
  final String password;
  final String? email;
  final String? name;

  @override
  List<Object?> get props => [countryCode, phone, password, email, name];
}

/// `PATCH /users/me` with the picked photo as the multipart `avatar` part.
class AuthenticationProfilePhotoUpdated extends AuthenticationEvent {
  const AuthenticationProfilePhotoUpdated({
    required this.avatar,
    this.avatarFileName,
  });

  final Uint8List avatar;
  final String? avatarFileName;

  @override
  List<Object?> get props => [avatar, avatarFileName];
}

/// `POST /auth/logout`, then forget the tokens.
class AuthenticationSignOutRequested extends AuthenticationEvent {
  const AuthenticationSignOutRequested();
}

/// `POST /auth/delete-account`, then forget the tokens.
///
/// The password is re-typed at the confirmation screen: a session on its own
/// must not be enough to destroy an account.
class AuthenticationDeleteAccountRequested extends AuthenticationEvent {
  const AuthenticationDeleteAccountRequested({required this.password});

  final String password;

  @override
  List<Object?> get props => [password];
}

/// `POST /auth/restore-account` — undoes a deletion and signs straight in.
///
/// Carries the number and password rather than relying on a session, because
/// deleting the account revoked every token it had.
class AuthenticationAccountRestoreRequested extends AuthenticationEvent {
  const AuthenticationAccountRestoreRequested({
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

/// The UI has shown [AuthenticationState.notice]; clear it.
class AuthenticationNoticeDismissed extends AuthenticationEvent {
  const AuthenticationNoticeDismissed();
}
