/// Where the app talks to the PiggyPal mobile API, and how patiently.
///
/// The base URL is a compile-time constant so a build can be pointed at a
/// local server or staging without touching code:
///
/// ```sh
/// flutter run --dart-define=PIGGYPAL_API_BASE_URL=http://192.168.1.10:3000/api/v1/piggypal.d
/// ```
///
/// Note that `localhost` only means "this machine" — which on a device or an
/// emulator is the phone, not your Mac. Point a local build at your LAN IP
/// (or `10.0.2.2` on the Android emulator, its alias for the host).
abstract final class ApiConfig {
  ApiConfig._();

  /// Host and prefix, no trailing slash. The prefix matches `API_PREFIX` in
  /// the API's `.env` (`/api/v1/piggypal.d`) — the two have to agree or every
  /// call 404s.
  static const _override = String.fromEnvironment('PIGGYPAL_API_BASE_URL');

  /// The deployed API. Used unless a build overrides it with the
  /// `--dart-define` above.
  static const defaultBaseUrl =
      'https://piggypal-mobile-api.onrender.com/api/v1/piggypal.d';

  /// The base URL every request is resolved against.
  static String get baseUrl => _override.isEmpty ? defaultBaseUrl : _override;

  /// Establishing the socket. Still the shortest of the three — a genuinely
  /// unreachable host should fail fast — but roomy enough for a phone on a
  /// slow mobile connection.
  static const connectTimeout = Duration(seconds: 30);

  /// Waiting for the response body once the request is on the wire. Generous,
  /// because Render's free tier spins the service down when idle and the first
  /// request after a quiet period pays a cold start of up to a minute. It also
  /// covers sign-up, which hashes a password with bcrypt (12 rounds) and may
  /// carry an avatar upload.
  static const receiveTimeout = Duration(seconds: 90);

  /// Sending the request body — matters for multipart avatar uploads, which on
  /// a cold instance wait on the same spin-up.
  static const sendTimeout = Duration(seconds: 60);

  /// How long a request may run before the UI explains the wait.
  ///
  /// A warm response lands well inside this; anything past it is almost
  /// certainly the cold start above, so it is worth saying so rather than
  /// leaving a spinner turning. See `ServerWakeupNotifier`.
  static const slowRequestThreshold = Duration(seconds: 5);
}
