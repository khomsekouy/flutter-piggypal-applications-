import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/app/view/server_wakeup_banner.dart';
import 'package:flutter_piggypal_app/core/network/api_config.dart';
import 'package:flutter_piggypal_app/core/network/dio_client.dart';
import 'package:flutter_piggypal_app/core/network/server_wakeup.dart';
import 'package:flutter_piggypal_app/l10n/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

/// An adapter that answers nothing until the test says so — which is what a
/// cold-starting instance looks like from the client's side.
class _StallingApi implements HttpClientAdapter {
  final completer = Completer<ResponseBody>();

  /// The options dio actually sent, captured for [answerOffline].
  late final RequestOptions sent;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    sent = options;
    return completer.future;
  }

  @override
  void close({bool force = false}) {}

  void answerOk() => completer.complete(
    ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    ),
  );

  /// [options] is the object dio handed [fetch]; a real adapter reports the
  /// failure against that same request.
  void answerOffline(RequestOptions options) => completer.completeError(
    DioException.connectionError(
      requestOptions: options,
      reason: 'Connection refused',
    ),
  );

  /// A failure reported against a request the interceptor never saw — what
  /// `DioMixin.assureDioException` lets a hand-built `DioException` do.
  void answerWithForeignError() => completer.completeError(
    DioException.connectionError(
      requestOptions: RequestOptions(path: '/somewhere-else'),
      reason: 'Connection refused',
    ),
  );
}

void main() {
  final banner = find.text('Waking the server up…');

  // The notifier is a process-wide singleton, so anything a test leaves behind
  // would show up as a banner in the next one.
  tearDown(ServerWakeupNotifier.instance.reset);

  Widget harness() => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) =>
        ServerWakeupBanner(child: child ?? const SizedBox.shrink()),
    home: const Scaffold(),
  );

  /// Pumps the banner over an empty app and puts one request in flight.
  ///
  /// Both the client and the request have to be created inside the test body:
  /// `setUp` runs outside `testWidgets`' fake-async zone, and a future created
  /// there never completes against the fake clock the timer is running on.
  Future<_StallingApi> pumpWithRequestInFlight(WidgetTester tester) async {
    final api = _StallingApi();
    final dio = buildDio(
      readAccessToken: () async => null,
      dio: Dio()..httpClientAdapter = api,
    );

    await tester.pumpWidget(harness());
    // The outcome is beside the point here — every test is about the banner.
    unawaited(
      dio
          .get<dynamic>('/anything')
          .then<void>((_) {})
          .catchError((Object _) {}),
    );
    await tester.pump();

    return api;
  }

  /// Runs past the threshold and lets the banner animate in.
  Future<void> outlastThreshold(WidgetTester tester) async {
    await tester.pump(ApiConfig.slowRequestThreshold);
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('stays hidden while a request is still young', (tester) async {
    final api = await pumpWithRequestInFlight(tester);

    await tester.pump(
      ApiConfig.slowRequestThreshold - const Duration(seconds: 1),
    );
    expect(banner, findsNothing);

    api.answerOk();
    await tester.pumpAndSettle();
  });

  testWidgets('explains the wait once a request outlasts the threshold', (
    tester,
  ) async {
    final api = await pumpWithRequestInFlight(tester);

    await outlastThreshold(tester);
    expect(banner, findsOneWidget);

    api.answerOk();
    await tester.pumpAndSettle();
  });

  testWidgets('goes away when the response finally lands', (tester) async {
    final api = await pumpWithRequestInFlight(tester);
    await outlastThreshold(tester);
    expect(banner, findsOneWidget);

    api.answerOk();
    await tester.pumpAndSettle();

    expect(banner, findsNothing);
  });

  testWidgets('goes away when the request fails instead', (tester) async {
    final api = await pumpWithRequestInFlight(tester);
    await outlastThreshold(tester);
    expect(banner, findsOneWidget);

    api.answerOffline(api.sent);
    await tester.pumpAndSettle();

    expect(banner, findsNothing);
  });

  testWidgets('clears itself if the failure names a request it never saw', (
    tester,
  ) async {
    final api = await pumpWithRequestInFlight(tester);
    await outlastThreshold(tester);
    expect(banner, findsOneWidget);

    // Nothing matches the entry, so only the guard can clear it.
    api.answerWithForeignError();
    await tester.pump();
    expect(banner, findsOneWidget);

    await tester.pump(ApiConfig.connectTimeout + ApiConfig.receiveTimeout);
    await tester.pumpAndSettle();

    expect(banner, findsNothing);
  });
}
