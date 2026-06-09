import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/savings_goals/domain/entities/savings_goal.dart';
import 'package:flutter_piggypal_app/features/savings_goals/domain/repositories/savings_goal_repository.dart';

class CreateGoal extends UseCase<SavingsGoal, CreateGoalParams> {
  const CreateGoal(this._repository);

  final SavingsGoalRepository _repository;

  @override
  ResultFuture<SavingsGoal> call(CreateGoalParams params) =>
      _repository.createGoal(params.goal);
}

class CreateGoalParams extends Equatable {
  const CreateGoalParams(this.goal);

  final SavingsGoal goal;

  @override
  List<Object?> get props => [goal];
}
