import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/entities/auth_user.dart';

/// What `POST /auth/login` and `POST /auth/register` both hand back: a pair of
/// tokens and the account they belong to.
///
/// The access token is short-lived (15 minutes) and goes on every request; the
/// refresh token is long-lived, identifies this one device's session, and is
/// what `POST /auth/logout` revokes.
class AuthSession extends Equatable {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    this.message,
  });

  final String accessToken;
  final String refreshToken;
  final AuthUser user;

  /// The server's own wording ("Signed in successfully"), worth showing rather
  /// than inventing our own.
  final String? message;

  @override
  List<Object?> get props => [accessToken, refreshToken, user, message];
}
