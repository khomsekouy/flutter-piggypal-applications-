import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/savings_goals/domain/repositories/savings_goal_repository.dart';

class DeleteGoal extends UseCase<void, DeleteGoalParams> {
  const DeleteGoal(this._repository);

  final SavingsGoalRepository _repository;

  @override
  ResultVoid call(DeleteGoalParams params) =>
      _repository.deleteGoal(params.goalId);
}

class DeleteGoalParams extends Equatable {
  const DeleteGoalParams(this.goalId);

  final String goalId;

  @override
  List<Object?> get props => [goalId];
}
