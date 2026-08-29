import 'dart:async';

import 'package:flutter_piggypal_app/core/error/exceptions.dart';
import 'package:flutter_piggypal_app/features/authentication/data/datasources/auth_token_store.dart';
import 'package:flutter_piggypal_app/features/authentication/data/datasources/authentication_remote_data_source.dart';

/// Rotates the token pair when the access token has expired.
///
/// Sits between the dio interceptor and `POST /auth/refresh`, and exists to
/// guarantee one thing the API is strict about: a refresh token is spent
/// **once**. Presenting a retired one is read server-side as a leak and drops
/// every session the account has — so two concurrent 401s must not become two
/// refreshes. Hence the single-flight future below, plus the check that the
/// caller's token is still the current one before rotating at all.
class AuthSessionRefresher {
  AuthSessionRefresher(this._remote, this._tokens);

  final AuthenticationRemoteDataSource _remote;
  final AuthTokenStore _tokens;

  /// The rotation in progress, shared by every caller that arrives during it.
  Future<bool>? _inFlight;

  final _expired = StreamController<void>.broadcast();

  /// Emits when the session is gone for good — the refresh token was rejected,
  /// so nothing short of signing in again will help.
  Stream<void> get sessionExpired => _expired.stream;

  /// Whether there is a usable access token when this completes.
  ///
  /// [usedAccessToken] is the token whose request just got a 401. If the store
  /// already holds a different one, another caller rotated while this one was
  /// queued and there is nothing to do.
  Future<bool> refresh({String? usedAccessToken}) {
    final pending = _inFlight;
    if (pending != null) return pending;

    final attempt = _rotate(usedAccessToken).whenComplete(() {
      _inFlight = null;
    });
    _inFlight = attempt;
    return attempt;
  }

  Future<bool> _rotate(String? usedAccessToken) async {
    final current = await _tokens.readAccessToken();
    if (usedAccessToken != null &&
        current != null &&
        current != usedAccessToken) {
      // Someone else already refreshed; the caller only has to retry.
      return true;
    }

    final refreshToken = await _tokens.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final session = await _remote.refresh(
        refreshToken: refreshToken,
        deviceId: await _tokens.deviceId(),
        deviceName: _tokens.deviceName,
      );
      // Stored before anything is retried: the token just spent is already
      // dead server-side, and a second call with it would look like a leak.
      await _tokens.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      return true;
    } on UnauthorizedException {
      // Expired, revoked, or rotated away — the session is over.
      await _tokens.clear();
      _expired.add(null);
      return false;
    } on Exception {
      // A network blip is not a dead session: keep the tokens, fail this one
      // request, and let the next attempt try again.
      return false;
    }
  }

  Future<void> dispose() => _expired.close();
}
