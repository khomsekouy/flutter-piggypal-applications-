import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/app/app.dart';
import 'package:flutter_piggypal_app/core/database/app_database.dart';
import 'package:flutter_piggypal_app/core/di/injection_container.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/widgets/gradient_button.dart';
import 'package:flutter_piggypal_app/l10n/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

/// Registers all app dependencies against a fresh in-memory database.
///
/// Call this in `setUp` for widget tests that build real pages/blocs. Pair with
/// [tearDownDependencies] to reset the service locator between tests.
Future<void> setUpDependencies() async {
  await sl.reset();
  await initDependencies(
    database: AppDatabase.forTesting(NativeDatabase.memory()),
  );
}

Future<void> tearDownDependencies() => sl.reset();

extension PumpApp on WidgetTester {
  Future<void> pumpApp(Widget widget) {
    return pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: widget,
      ),
    );
  }

  /// Pumps the real [App] and drives splash → sign-in → home, leaving the
  /// tree on the Training Finance dashboard.
  ///
  /// [App] no longer renders the module directly: it starts on the splash
  /// route and reaches `/home` only through the auth flow. Tests that want
  /// the dashboard have to walk that path.
  ///
  /// Note that `AppRouter.router` is a `static final`, so its location
  /// persists for the lifetime of the isolate — call this once per test file,
  /// or the second call starts from wherever the first one finished.
  Future<void> pumpAppToHome() async {
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
