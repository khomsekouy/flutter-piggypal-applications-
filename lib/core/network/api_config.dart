import 'package:flutter/foundation.dart';

/// Where the app talks to the PiggyPal mobile API, and how patiently.
///
/// The base URL is a compile-time constant so a build can be pointed at
/// staging without touching code:
///
/// ```sh
/// flutter run --dart-define=PIGGYPAL_API_BASE_URL=http://192.168.1.10:3000/api/v1/piggypal.d
/// ```
///
/// `localhost` only means "this machine" — which on a device or an emulator is
/// the phone, not your Mac. [defaultBaseUrl] resolves that for the Android
/// emulator (`10.0.2.2` is its alias for the host); a real handset needs the
/// `--dart-define` above with your LAN IP.
abstract final class ApiConfig {
  ApiConfig._();

  /// Host and prefix, no trailing slash. Matches `API_PREFIX` in the API's
  /// `.env` (`/api/v1/piggypal.d`) — the two have to agree or every call 404s.
  static const _override = String.fromEnvironment('PIGGYPAL_API_BASE_URL');

  static const _prefix = '/api/v1/piggypal.d';

  static String get defaultBaseUrl {
    final host = defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:3000'
        : 'http://localhost:3000';
    return '$host$_prefix';
  }

  /// The base URL every request is resolved against.
  static String get baseUrl => _override.isEmpty ? defaultBaseUrl : _override;

  /// Establishing the socket. Short: an unreachable host should fail fast.
  static const connectTimeout = Duration(seconds: 15);

  /// Waiting for the response body once the request is on the wire. Longer,
  /// because sign-up hashes a password with bcrypt (12 rounds) and may carry
  /// an avatar upload.
  static const receiveTimeout = Duration(seconds: 30);

  /// Sending the request body — matters for multipart avatar uploads.
  static const sendTimeout = Duration(seconds: 30);
}
