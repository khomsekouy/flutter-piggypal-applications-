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

  /// Bumped by [abandon]. A rotation carries the value it started under, and
  /// one that comes back under a different value is dropped rather than
  /// written to the store.
  int _generation = 0;

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

    final generation = _generation;
    final attempt = _rotate(generation, usedAccessToken).whenComplete(() {
      // Only while this is still the rotation everyone is waiting on.
      // [abandon] has already emptied the slot, and a caller arriving after it
      // may own it by now.
      if (generation == _generation) _inFlight = null;
    });
    _inFlight = attempt;
    return attempt;
  }

  /// Gives up on whatever rotation is in flight, because the session it
  /// belongs to is over by the user's own choice — sign-out.
  ///
  /// The request cannot be recalled, but its answer can be thrown away, and it
  /// has to be. A pair saved after the store was cleared puts a working
  /// session back on a device the user just signed out of; a 401 handled after
  /// the same clear announces an expiry for a session nobody expected to
  /// outlive the tap.
  void abandon() {
    _generation += 1;
    // Nothing may join the abandoned attempt: a caller arriving after this has
    // to rotate against whatever session exists then, if any.
    _inFlight = null;
  }

  Future<bool> _rotate(int generation, String? usedAccessToken) async {
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
      // Nothing is stored once the session has been abandoned — see [abandon].
      if (generation != _generation) return false;
      // Stored before anything is retried: the token just spent is already
      // dead server-side, and a second call with it would look like a leak.
      await _tokens.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      return true;
    } on UnauthorizedException {
      // Expired, revoked, or rotated away — the session is over. Unless it was
      // already over on purpose, in which case saying so twice is worse than
      // not saying it at all.
      if (generation != _generation) return false;
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
