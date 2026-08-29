import 'package:dio/dio.dart';

/// Attaches the bearer token to every request that needs one.
///
/// Reads the token per request rather than holding it: sign-in, sign-up and
/// sign-out all change it, and an interceptor that cached it would keep
/// sending the token of the account that just signed out.
///
/// Opt a request out with `Options(extra: {AuthInterceptor.skipAuth: true})` —
/// used by sign-in, sign-up and refresh, which mint a session rather than use
/// one.
class AuthInterceptor extends Interceptor {
  const AuthInterceptor(this._readAccessToken);

  /// Set on a request's `extra` to send it without the `Authorization` header.
  static const skipAuth = 'skipAuth';

  final Future<String?> Function() _readAccessToken;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[skipAuth] == true) {
      handler.next(options);
      return;
    }

    final token = await _readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
