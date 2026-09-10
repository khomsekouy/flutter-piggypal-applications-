import 'package:equatable/equatable.dart';

/// The short-lived ticket that proves the code was verified.
///
/// Minted by `POST /auth/verify-otp` and spent by `POST /auth/reset-password`.
/// It is **not** a session: it is signed with the API's own reset secret and
/// carries `typ: pwd_reset`, so it authenticates nothing except the one
/// password change it was issued for.
///
/// Lives for ten minutes (`PASSWORD_RESET_TOKEN_TTL_MINUTES`) and is good for
/// exactly one use — the verification row behind it is consumed on success.
/// Nothing stores it: it travels from the code screen to the new-password
/// screen and dies with them.
class PasswordResetToken extends Equatable {
  const PasswordResetToken({required this.token});

  /// The opaque JWT to hand back to `reset-password`.
  final String token;

  @override
  List<Object?> get props => [token];
}
