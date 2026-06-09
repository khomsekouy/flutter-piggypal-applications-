import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_piggypal_app/core/database/tables/savings_goals_table.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// The single Drift database for the whole app.
///
/// New features add their table to the [DriftDatabase.tables] list and bump
/// [schemaVersion] (with a migration). Feature data sources receive this
/// instance via dependency injection and run their own queries against it.
@DriftDatabase(tables: [SavingsGoals])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// In-memory database for tests.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;
}

QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'piggypal.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
