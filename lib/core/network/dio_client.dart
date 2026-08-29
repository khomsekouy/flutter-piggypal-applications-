import 'package:dio/dio.dart';
import 'package:flutter_piggypal_app/core/network/api_config.dart';
import 'package:flutter_piggypal_app/core/network/interceptors/api_log_interceptor.dart';
import 'package:flutter_piggypal_app/core/network/interceptors/auth_interceptor.dart';
import 'package:flutter_piggypal_app/core/network/interceptors/refresh_interceptor.dart';
import 'package:flutter_piggypal_app/core/network/interceptors/slow_request_interceptor.dart';

/// Builds the single [Dio] the whole app shares.
///
/// One instance, not one per data source: the base URL, timeouts and the
/// bearer-token interceptor are the same everywhere, and sharing it means a
/// connection pool that is actually reused.
///
/// [readAccessToken] is called on every outgoing request — see
/// [AuthInterceptor]. [refreshSession], when given, adds the retry-on-401
/// behaviour described in [RefreshInterceptor]; leave it out for a client that
/// should simply report the 401. [dio] lets tests hand in an instance with a
/// stubbed adapter instead of one that talks to a real server.
Dio buildDio({
  required Future<String?> Function() readAccessToken,
  Future<bool> Function(String? usedAccessToken)? refreshSession,
  Dio? dio,
}) {
  final client = dio ?? Dio();

  client.options = client.options.copyWith(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
    sendTimeout: ApiConfig.sendTimeout,
    contentType: Headers.jsonContentType,
    responseType: ResponseType.json,
    // Every non-2xx becomes a DioException we map in one place
    // (`mapDioException`), rather than each call site re-checking the status.
    validateStatus: (status) => status != null && status >= 200 && status < 300,
  );

  // First in the chain on purpose — see SlowRequestInterceptor.
  client.interceptors.add(SlowRequestInterceptor());

  client.interceptors.add(AuthInterceptor(readAccessToken));

  if (refreshSession != null) {
    client.interceptors.add(
      RefreshInterceptor(
        refreshSession: refreshSession,
        readAccessToken: readAccessToken,
        // `fetch`, not `request`: the replay must not run the interceptor
        // chain again, or a still-401 response would queue another refresh.
        retry: client.fetch<dynamic>,
      ),
    );
  }

  client.interceptors.add(const ApiLogInterceptor());

  return client;
}
