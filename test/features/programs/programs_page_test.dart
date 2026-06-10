import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_piggypal_app/app/app.dart';
import 'package:flutter_piggypal_app/core/database/app_database.dart';
import 'package:flutter_piggypal_app/core/di/injection_container.dart';
import 'package:flutter_piggypal_app/features/programs/presentation/view/programs_page.dart';
import 'package:flutter_piggypal_app/features/programs/presentation/widgets/program_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() async {
    await sl.reset();
    // In-memory DB; initDependencies seeds the programs table from the design
    // dataset, so the wired list has content.
    await initDependencies(
      database: AppDatabase.forTesting(NativeDatabase.memory()),
    );
  });

  tearDown(() async {
    await sl<AppDatabase>().close();
    await sl.reset();
  });

  testWidgets('Programs tab renders Drift-seeded programs via the bloc',
      (tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    // Navigate to the Programs tab (bottom-nav label).
    await tester.tap(find.text('Programs').first);
    await tester.pumpAndSettle();

    expect(find.byType(ProgramsPage), findsOneWidget);
    // Seeded content from the database (not a hard-coded widget).
    expect(find.byType(ProgramCard), findsWidgets);
    expect(find.text('Advanced Data Analytics Bootcamp'), findsOneWidget);

    // Dispose the tree so the bloc closes its Drift stream subscription
    // before the test ends (avoids a lingering query-stream timer).
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
