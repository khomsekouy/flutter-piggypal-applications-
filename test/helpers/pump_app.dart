import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/core/database/app_database.dart';
import 'package:flutter_piggypal_app/core/di/injection_container.dart';
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
}
