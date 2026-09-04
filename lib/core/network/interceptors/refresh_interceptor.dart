import 'package:dio/dio.dart';
import 'package:flutter_piggypal_app/core/network/interceptors/auth_interceptor.dart';

/// Turns an expired access token into one retry instead of a sign-out.
///
/// On a 401 it asks `refreshSession` to mint a new token pair, then replays the
/// original request with the new token. The caller never learns it happened.
///
/// Deliberately a plain [Interceptor] and not a `QueuedInterceptor`: the
/// refresh call travels on this same client, so a queue that is busy awaiting
/// it would hold that call's own response behind the request waiting for it —
/// a deadlock that shows up as a hang, not an error. Concurrency is handled
/// where it belongs instead, by the single-flight guard behind
/// `refreshSession`: three requests failing together produce one refresh, not
/// three. That matters more here than usual — the API *rotates* refresh tokens
/// and treats a second use of a retired one as a leak, dropping every session
/// the account has. Sending the same refresh token twice would sign the user
/// out everywhere.
///
/// `refreshSession` receives the access token the failed request actually used,
/// so it can tell "my token expired" from "someone else already replaced it
/// while I was queued" and skip a redundant rotation. It returns whether there
/// is a usable session afterwards.
class RefreshInterceptor extends Interceptor {
  RefreshInterceptor({
    required Future<bool> Function(String? usedAccessToken) refreshSession,
    required Future<String?> Function() readAccessToken,
    required Future<Response<dynamic>> Function(RequestOptions options) retry,
  }) : _refreshSession = refreshSession,
       _readAccessToken = readAccessToken,
       _retry = retry;

  /// Set on a request's `extra` to let its 401 through untouched — used by the
  /// refresh call itself, which would otherwise refresh in a loop.
  static const skipRefresh = 'skipRefresh';

  /// Marks the replay, so a request can only ever be retried once.
  static const _retried = 'refreshRetried';

  final Future<bool> Function(String? usedAccessToken) _refreshSession;
  final Future<String?> Function() _readAccessToken;
  final Future<Response<dynamic>> Function(RequestOptions options) _retry;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;

    if (err.response?.statusCode != 401 ||
        options.extra[skipRefresh] == true ||
        options.extra[AuthInterceptor.skipAuth] == true ||
        options.extra[_retried] == true) {
      handler.next(err);
      return;
    }

    final usedToken = _bearerOf(options);
    if (!await _refreshSession(usedToken)) {
      // No session left to retry with — the 401 is the honest answer.
      handler.next(err);
      return;
    }

    final token = await _readAccessToken();
    if (token == null || token.isEmpty) {
      handler.next(err);
      return;
    }

    // The replay carries the new token itself rather than leaving it to the
    // auth interceptor to put back.
    options
      ..headers['Authorization'] = 'Bearer $token'
      ..extra[_retried] = true;

    // A multipart body is a one-shot stream: dio finalised it to send the
    // first attempt, and finalising it again throws. `clone()` is dio's own
    // answer to this. Without it the replay never reaches the wire, the
    // StateError arrives as a `DioExceptionType.unknown`, and an avatar
    // upload that only needed a fresh token reports "check your connection"
    // and loses the picture.
    final body = options.data;
    if (body is FormData) options.data = body.clone();

    try {
      handler.resolve(await _retry(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  String? _bearerOf(RequestOptions options) {
    final header = options.headers['Authorization'];
    return header is String ? header.replaceFirst('Bearer ', '') : null;
  }
}
