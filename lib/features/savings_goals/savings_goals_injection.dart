import 'package:flutter_piggypal_app/core/di/injection_container.dart';
import 'package:flutter_piggypal_app/features/savings_goals/data/datasources/savings_goal_local_data_source.dart';
import 'package:flutter_piggypal_app/features/savings_goals/data/repositories/savings_goal_repository_impl.dart';
import 'package:flutter_piggypal_app/features/savings_goals/domain/repositories/savings_goal_repository.dart';
import 'package:flutter_piggypal_app/features/savings_goals/domain/usecases/add_contribution.dart';
import 'package:flutter_piggypal_app/features/savings_goals/domain/usecases/create_goal.dart';
import 'package:flutter_piggypal_app/features/savings_goals/domain/usecases/delete_goal.dart';
import 'package:flutter_piggypal_app/features/savings_goals/domain/usecases/watch_goals.dart';
import 'package:flutter_piggypal_app/features/savings_goals/presentation/bloc/savings_goals_bloc.dart';

/// Wires the savings-goals feature into the service locator.
/// Called once from [initDependencies].
void initSavingsGoals() {
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
