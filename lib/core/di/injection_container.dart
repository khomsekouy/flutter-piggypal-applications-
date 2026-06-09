import 'package:flutter_piggypal_app/core/database/app_database.dart';
import 'package:flutter_piggypal_app/features/savings_goals/data/datasources/savings_goal_local_data_source.dart';
import 'package:flutter_piggypal_app/features/savings_goals/data/repositories/savings_goal_repository_impl.dart';
import 'package:flutter_piggypal_app/features/savings_goals/domain/repositories/savings_goal_repository.dart';
import 'package:flutter_piggypal_app/features/savings_goals/domain/usecases/add_contribution.dart';
import 'package:flutter_piggypal_app/features/savings_goals/domain/usecases/create_goal.dart';
import 'package:flutter_piggypal_app/features/savings_goals/domain/usecases/delete_goal.dart';
import 'package:flutter_piggypal_app/features/savings_goals/domain/usecases/watch_goals.dart';
import 'package:flutter_piggypal_app/features/savings_goals/presentation/bloc/savings_goals_bloc.dart';
import 'package:flutter_piggypal_app/features/transactions/data/datasources/transaction_local_data_source.dart';
import 'package:flutter_piggypal_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:flutter_piggypal_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter_piggypal_app/features/transactions/domain/usecases/add_transaction.dart';
import 'package:flutter_piggypal_app/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:flutter_piggypal_app/features/transactions/domain/usecases/watch_transactions.dart';
import 'package:flutter_piggypal_app/features/transactions/presentation/bloc/transactions_bloc.dart';
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
/// New features register their own dependencies in a `init<Feature>()` helper
/// called from here, keeping this file readable as the app grows.
/// [database] lets tests inject an in-memory database; production passes none.
Future<void> initDependencies({AppDatabase? database}) async {
  _initCore(database);
  _initSavingsGoals();
  _initTransactions();
}

void _initCore(AppDatabase? database) {
  sl.registerLazySingleton<AppDatabase>(() => database ?? AppDatabase());
}

void _initSavingsGoals() {
  sl
    // Bloc — fresh per screen.
    ..registerFactory(
      () => SavingsGoalsBloc(
        watchGoals: sl(),
        createGoal: sl(),
        addContribution: sl(),
        deleteGoal: sl(),
      ),
    )
    // Use cases.
    ..registerLazySingleton(() => WatchGoals(sl()))
    ..registerLazySingleton(() => CreateGoal(sl()))
    ..registerLazySingleton(() => AddContribution(sl()))
    ..registerLazySingleton(() => DeleteGoal(sl()))
    // Repository.
    ..registerLazySingleton<SavingsGoalRepository>(
      () => SavingsGoalRepositoryImpl(sl()),
    )
    // Data source.
    ..registerLazySingleton<SavingsGoalLocalDataSource>(
      () => SavingsGoalLocalDataSourceImpl(sl()),
    );
}

void _initTransactions() {
  sl
    // Bloc — fresh per screen.
    ..registerFactory(
      () => TransactionsBloc(
        watchTransactions: sl(),
        addTransaction: sl(),
        deleteTransaction: sl(),
      ),
    )
    // Use cases.
    ..registerLazySingleton(() => WatchTransactions(sl()))
    ..registerLazySingleton(() => AddTransaction(sl()))
    ..registerLazySingleton(() => DeleteTransaction(sl()))
    // Repository.
    ..registerLazySingleton<TransactionRepository>(
      () => TransactionRepositoryImpl(sl()),
    )
    // Data source.
    ..registerLazySingleton<TransactionLocalDataSource>(
      () => TransactionLocalDataSourceImpl(sl()),
    );
}
