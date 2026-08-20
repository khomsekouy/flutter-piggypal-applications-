import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logs one line per request and per response, in debug builds only.
///
/// Deliberately *not* dio's own `LogInterceptor`: that prints bodies and
/// headers, which here means passwords, access tokens and refresh tokens in
/// the console. Method, path and status are enough to follow a flow.
class ApiLogInterceptor extends Interceptor {
  const ApiLogInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      log('→ ${options.method} ${options.uri.path}', name: 'api');
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      log(
        '← ${response.statusCode} ${response.requestOptions.method} '
        '${response.requestOptions.uri.path}',
        name: 'api',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      log(
        '✗ ${err.response?.statusCode ?? err.type.name} '
        '${err.requestOptions.method} ${err.requestOptions.uri.path}',
        name: 'api',
      );
    }
    handler.next(err);
  }
}
