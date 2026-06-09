import 'package:flutter_piggypal_app/core/error/exceptions.dart';
import 'package:flutter_piggypal_app/core/error/failures.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/savings_goals/data/datasources/savings_goal_local_data_source.dart';
import 'package:flutter_piggypal_app/features/savings_goals/data/models/savings_goal_model.dart';
import 'package:flutter_piggypal_app/features/savings_goals/domain/entities/savings_goal.dart';
import 'package:flutter_piggypal_app/features/savings_goals/domain/repositories/savings_goal_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Bridges the domain contract to the local data source.
///
/// Its job is error translation: data-source [Exception]s become typed
/// [Failure]s wrapped in an `Either`, so the rest of the app never deals with
/// try/catch.
class SavingsGoalRepositoryImpl implements SavingsGoalRepository {
  const SavingsGoalRepositoryImpl(this._local);

  final SavingsGoalLocalDataSource _local;

  @override
  ResultFuture<List<SavingsGoal>> getGoals() async {
    try {
      return Right(await _local.getGoals());
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  ResultStream<List<SavingsGoal>> watchGoals() => _local.watchGoals();

  @override
  ResultFuture<SavingsGoal> createGoal(SavingsGoal goal) =>
      _save(SavingsGoalModel.fromEntity(goal));

  @override
  ResultFuture<SavingsGoal> updateGoal(SavingsGoal goal) =>
      _save(SavingsGoalModel.fromEntity(goal));

  Future<Either<Failure, SavingsGoal>> _save(SavingsGoalModel model) async {
    try {
      return Right(await _local.upsertGoal(model));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  ResultFuture<SavingsGoal> addContribution({
    required String goalId,
    required double amount,
  }) async {
    try {
      return Right(await _local.addContribution(goalId, amount));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  ResultVoid deleteGoal(String goalId) async {
    try {
      await _local.deleteGoal(goalId);
      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }
}
