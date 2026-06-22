import 'package:flutter_piggypal_app/core/database/app_database.dart';
import 'package:flutter_piggypal_app/features/programs/data/datasources/programs_local_data_source.dart';
import 'package:flutter_piggypal_app/features/programs/data/programs_seed.dart';
import 'package:flutter_piggypal_app/features/programs/programs_injection.dart';
import 'package:flutter_piggypal_app/features/savings_goals/savings_goals_injection.dart';
import 'package:flutter_piggypal_app/features/transactions/transactions_injection.dart';
import 'package:get_it/get_it.dart';

/// The app's service locator. `sl` == "service locator".
final GetIt sl = GetIt.instance;

/// Registers every dependency, wiring the layers together exactly once.
///
/// Convention:
///   * singletons for things that should live for the app's lifetime
///     (database, data sources, repositories, use cases — they're stateless);
///   * factories for BLoCs, so each screen gets a fresh instance it owns.
///
/// Each feature owns its wiring in an `init<Feature>()` helper that lives
/// beside the feature (e.g. `features/programs/programs_injection.dart`).
/// This file just registers core and calls them in order.
/// [database] lets tests inject an in-memory database; production passes none.
Future<void> initDependencies({AppDatabase? database}) async {
  _initCore(database);
  initSavingsGoals();
  initTransactions();
  initPrograms();

  // Seed the programs table on first run so the wired list has content.
  await seedPrograms(sl<ProgramsLocalDataSource>());
}

void _initCore(AppDatabase? database) {
  sl.registerLazySingleton<AppDatabase>(() => database ?? AppDatabase());
}
