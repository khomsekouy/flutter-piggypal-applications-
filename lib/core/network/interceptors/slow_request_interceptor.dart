import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_piggypal_app/core/network/api_config.dart';
import 'package:flutter_piggypal_app/core/network/server_wakeup.dart';

/// Reports requests that outlast [ApiConfig.slowRequestThreshold] to
/// [ServerWakeupNotifier], so the UI can say what the wait is for.
///
/// Must be the *first* interceptor on the client. Dio runs every callback in
/// registration order, and an interceptor further down the chain may resolve
/// an error into a response — `RefreshInterceptor` does exactly that on a 401.
/// Anything registered after it would never see that error, and its timer
/// entry would never be cleared: a banner stuck on screen for the rest of the
/// session. First in line sees every outcome before it can be swallowed.
class SlowRequestInterceptor extends Interceptor {
  SlowRequestInterceptor({
    ServerWakeupNotifier? notifier,
    this.threshold = ApiConfig.slowRequestThreshold,
  }) : _notifier = notifier ?? ServerWakeupNotifier.instance;

  final ServerWakeupNotifier _notifier;

  /// How long a request may run before it is worth explaining.
  final Duration threshold;

  /// How long a slow request may stay on the banner before it is cleared
  /// regardless. A guard, not the normal path: dio hands back the request's
  /// own options object on the response and on the error, but a `DioException`
  /// built with a *different* `RequestOptions` is passed through untouched
  /// (`DioMixin.assureDioException`), and that one would never match its
  /// entry. Nothing outlives connect + receive, so by then the request is over
  /// whatever dio reported.
  static final Duration _maxVisible =
      ApiConfig.connectTimeout + ApiConfig.receiveTimeout;

  /// Keyed by the request's own options object. Holds the timer that will mark
  /// the request slow, then — once it has — the one that gives up on it.
  final _timers = <RequestOptions, Timer>{};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _timers[options] = Timer(threshold, () {
      _notifier.markSlow(options);
      _timers[options] = Timer(_maxVisible, () => _finish(options));
    });
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _finish(response.requestOptions);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _finish(err.requestOptions);
    handler.next(err);
  }

  void _finish(RequestOptions options) {
    // Cancelling a timer that already fired is a no-op, and marking a request
    // finished that was never marked slow is too — so both orderings are safe.
    _timers.remove(options)?.cancel();
    _notifier.markFinished(options);
  }
}
