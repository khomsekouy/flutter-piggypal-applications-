import 'package:flutter/foundation.dart';
import 'package:flutter_piggypal_app/core/error/exceptions.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Where the session lives between launches.
///
/// Three values: the access token (sent on every request), the refresh token
/// (the only thing that can revoke this device's session, so `POST
/// /auth/logout` needs it), and a device id generated once per install so a
/// single device can be signed out from the server side later.
abstract interface class AuthTokenStore {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();

  /// Stable per install, created on first read.
  Future<String> deviceId();

  /// A human-readable label for this install, shown in the session list.
  String get deviceName;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  /// Drops both tokens. The device id survives — it identifies the install,
  /// not the session.
  Future<void> clear();
}

/// Keychain (iOS/macOS) / EncryptedSharedPreferences (Android) backed store.
class SecureAuthTokenStore implements AuthTokenStore {
  SecureAuthTokenStore({FlutterSecureStorage? storage, Uuid? uuid})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            // Android needs no options: the plugin encrypts with its own
            // ciphers now, and `encryptedSharedPreferences` is deprecated.
            //
            // `first_unlock` rather than `unlocked`: the app may be woken in
            // the background before the user has unlocked the phone, and a
            // token it cannot read then is a session that looks signed out.
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          ),
      _uuid = uuid ?? const Uuid();

  static const _accessTokenKey = 'piggypal.auth.accessToken';
  static const _refreshTokenKey = 'piggypal.auth.refreshToken';
  static const _deviceIdKey = 'piggypal.auth.deviceId';

  final FlutterSecureStorage _storage;
  final Uuid _uuid;

  /// What the keychain is known to hold, by key, with `null` meaning "known to
  /// be empty". Every request reads the access token, and each keychain read
  /// is a platform-channel round trip; this store is the only thing that
  /// writes these keys, so after the first read the answer can be served from
  /// memory. A key missing from here has not been read yet — or a write to it
  /// failed and left the keychain in a state worth asking about again.
  final _cache = <String, String?>{};

  @override
  Future<String?> readAccessToken() => _read(_accessTokenKey);

  @override
  Future<String?> readRefreshToken() => _read(_refreshTokenKey);

  @override
  Future<String> deviceId() async {
    final existing = await _read(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final generated = _uuid.v4();
    await _write(_deviceIdKey, generated);
    return generated;
  }

  @override
  String get deviceName => 'PiggyPal ${defaultTargetPlatform.name}';

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _write(_accessTokenKey, accessToken);
    await _write(_refreshTokenKey, refreshToken);
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      _cache[_accessTokenKey] = null;
      await _storage.delete(key: _refreshTokenKey);
      _cache[_refreshTokenKey] = null;
    } on Exception catch (e) {
      _cache
        ..remove(_accessTokenKey)
        ..remove(_refreshTokenKey);
      throw SecureStorageException('$e');
    }
  }

  Future<String?> _read(String key) async {
    if (_cache.containsKey(key)) return _cache[key];
    try {
      return _cache[key] = await _storage.read(key: key);
    } on Exception {
      // A read that throws is treated as "nothing stored": the platform
      // channel is missing (tests, an unsupported desktop target) or the
      // keychain entry is unreadable. Either way there is no usable session,
      // and failing the whole launch over it would be worse than signing in
      // again. Not cached: a keychain that is merely locked right now may
      // answer on the next request.
      return null;
    }
  }

  Future<void> _write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      _cache[key] = value;
    } on Exception catch (e) {
      _cache.remove(key);
      // Writes do throw: losing the refresh token silently would leave a user
      // signed out on next launch with no explanation.
      throw SecureStorageException('$e');
    }
  }
}

/// In-memory store for tests and for `flutter test`, where the secure-storage
/// platform channel does not exist.
class InMemoryAuthTokenStore implements AuthTokenStore {
  InMemoryAuthTokenStore({String deviceId = 'test-device'})
    : _deviceId = deviceId;

  final String _deviceId;
  String? _accessToken;
  String? _refreshToken;

  @override
  Future<String?> readAccessToken() async => _accessToken;

  @override
  Future<String?> readRefreshToken() async => _refreshToken;

  @override
  Future<String> deviceId() async => _deviceId;

  @override
  String get deviceName => 'PiggyPal test';

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  @override
  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
  }
}
