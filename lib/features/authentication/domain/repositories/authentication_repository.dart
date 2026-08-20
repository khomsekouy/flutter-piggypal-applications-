import 'dart:typed_data';

import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/entities/auth_session.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/entities/auth_user.dart';

/// Domain contract for authentication.
///
/// Covers the four endpoints the app uses: sign in, sign up, sign out and
/// "who am I". The implementation also owns the tokens — callers never see
/// them, they just get an [AuthSession] back and every later request is
/// authenticated for them.
abstract interface class AuthenticationRepository {
  /// `POST /auth/login`. [phone] is the **national** number only (`97573235`);
  /// [countryCode] is the dialling code (`+855`). The server joins them.
  ResultFuture<AuthSession> signIn({
    required String countryCode,
    required String phone,
    required String password,
  });

  /// `POST /auth/register`.
  ///
  /// [avatar] is sent as a multipart file part, which is the only way this API
  /// accepts a profile picture — there is no `avatarUrl` field, and sending
  /// one is rejected outright by its strict validation. Leave it null and the
  /// request goes out as plain JSON.
  ResultFuture<AuthSession> signUp({
    required String countryCode,
    required String phone,
    required String password,
    String? email,
    String? name,
    Uint8List? avatar,
    String? avatarFileName,
  });

  /// `POST /auth/logout`, then clears the stored tokens.
  ///
  /// Succeeds even if the server call fails: the local session must go either
  /// way, or a user with no connection could not sign out at all.
  ResultVoid signOut();

  /// `GET /users/me` — the full profile, not the token's claims.
  ResultFuture<AuthUser> getCurrentUser();

  /// Whether a token is on disk. Cheap: no network, no validation — the splash
  /// screen uses it to decide whether it is worth calling [getCurrentUser].
  Future<bool> hasSession();

  /// Emits when a session ends on its own — the access token expired and the
  /// refresh token behind it was rejected, so the user is signed out wherever
  /// they happen to be standing in the app.
  ///
  /// Expiry mid-use is otherwise invisible: requests refresh and retry
  /// themselves, and only a refresh that fails reaches here.
  Stream<void> get sessionExpired;
}
