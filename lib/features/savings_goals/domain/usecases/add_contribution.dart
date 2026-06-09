import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/savings_goals/domain/entities/savings_goal.dart';
import 'package:flutter_piggypal_app/features/savings_goals/domain/repositories/savings_goal_repository.dart';

/// Deposits money into an existing goal.
class AddContribution extends UseCase<SavingsGoal, AddContributionParams> {
  const AddContribution(this._repository);

  final SavingsGoalRepository _repository;

  @override
  ResultFuture<SavingsGoal> call(AddContributionParams params) =>
      _repository.addContribution(
        goalId: params.goalId,
        amount: params.amount,
      );
}

class AddContributionParams extends Equatable {
  const AddContributionParams({required this.goalId, required this.amount});

  final String goalId;
  final double amount;

  @override
  List<Object?> get props => [goalId, amount];
}
