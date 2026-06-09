import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/savings_goals/domain/entities/savings_goal.dart';

/// The domain's contract for persisting and retrieving savings goals.
///
/// The domain layer depends only on this interface. The data layer provides
/// the concrete implementation, so the choice of Drift (or anything else) never
/// leaks upwards.
abstract interface class SavingsGoalRepository {
  /// One-shot read of all goals, newest first.
  ResultFuture<List<SavingsGoal>> getGoals();

  /// Live stream of all goals — emits again whenever the table changes.
  ResultStream<List<SavingsGoal>> watchGoals();

  ResultFuture<SavingsGoal> createGoal(SavingsGoal goal);

  ResultFuture<SavingsGoal> updateGoal(SavingsGoal goal);

  /// Adds [amount] to a goal's saved balance and returns the updated goal.
  ResultFuture<SavingsGoal> addContribution({
    required String goalId,
    required double amount,
  });

  ResultVoid deleteGoal(String goalId);
}
