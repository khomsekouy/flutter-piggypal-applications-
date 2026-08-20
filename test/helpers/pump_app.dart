import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_piggypal_app/app/app.dart';
import 'package:flutter_piggypal_app/core/database/app_database.dart';
import 'package:flutter_piggypal_app/core/di/injection_container.dart';
import 'package:flutter_piggypal_app/features/authentication/data/datasources/auth_token_store.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/gradient_button.dart';
import 'package:flutter_piggypal_app/l10n/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_auth_api.dart';

/// Registers all app dependencies against a fresh in-memory database, a
/// [FakeAuthApi] instead of a real server, and a token store that never
/// touches the keychain (its platform channel does not exist under
/// `flutter test`).
///
/// Call this in `setUp` for widget tests that build real pages/blocs. Pair
/// with [tearDownDependencies] to reset the service locator between tests.
/// The returned [FakeAuthApi] is how a test drives failures (`rejectLogin`)
/// and asserts which endpoints were called.
Future<FakeAuthApi> setUpDependencies({FakeAuthApi? api}) async {
  await sl.reset();
  final fakeApi = api ?? FakeAuthApi();
  await initDependencies(
    database: AppDatabase.forTesting(NativeDatabase.memory()),
    dio: Dio()..httpClientAdapter = fakeApi,
    tokenStore: InMemoryAuthTokenStore(),
  );
  return fakeApi;
}

/// Closes the in-memory database before resetting, so the next `setUp` does
/// not open a second one against the same executor (drift warns about it).
Future<void> tearDownDependencies() async {
  if (sl.isRegistered<AppDatabase>()) {
    await sl<AppDatabase>().close();
  }
  await sl.reset();
}

extension PumpApp on WidgetTester {
  /// Pumps [widget] on its own, under the app's localizations.
  ///
  /// Wraps it in an [AuthenticationBloc] provider when the service locator has
  /// one — which is what the auth screens read. Tests that pump a screen with
  /// no auth in it can skip [setUpDependencies] entirely and still work.
  Future<void> pumpApp(Widget widget) {
    final child = sl.isRegistered<AuthenticationBloc>()
        ? BlocProvider(create: (_) => sl<AuthenticationBloc>(), child: widget)
        : widget;

    return pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  /// Pumps the real [App] and drives splash → sign-in → home, leaving the
  /// tree on the Training Finance dashboard.
  ///
  /// [App] no longer renders the module directly: it starts on the splash
  /// route and reaches `/home` only through the auth flow, which now means a
  /// real `POST /auth/login` against [FakeAuthApi]. Tests that want the
  /// dashboard have to walk that path.
  ///
  /// Registers dependencies itself when a test has not already, since [App]
  /// resolves its bloc from the service locator.
  ///
  /// Note that `AppRouter.router` is a `static final`, so its location
  /// persists for the lifetime of the isolate — call this once per test file,
  /// or the second call starts from wherever the first one finished.
  Future<void> pumpAppToHome() async {
    if (!sl.isRegistered<AuthenticationBloc>()) {
      await setUpDependencies();
    }

    await pumpWidget(const App());
    await pump();
    // Outlast the splash hold (1800ms) so it routes on to sign-in.
    await pump(const Duration(seconds: 2));
    await pumpAndSettle();

    // 8 digits is a valid Cambodian number, the default country.
    await enterText(find.byType(TextField).at(0), '12345678');
    await enterText(find.byType(TextField).at(1), 'supersecret');
    await pump();

    // The button sits below the fold at the default 800x600 surface, and
    // resizing here would change what the dashboard tests are measuring.
    await ensureVisible(find.byType(GradientButton));
    await pumpAndSettle();
    await tap(find.byType(GradientButton));
    await pumpAndSettle();
  }
}
