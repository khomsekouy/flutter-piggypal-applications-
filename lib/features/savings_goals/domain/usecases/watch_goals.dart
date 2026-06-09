import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/savings_goals/domain/entities/savings_goal.dart';
import 'package:flutter_piggypal_app/features/savings_goals/domain/repositories/savings_goal_repository.dart';

/// Streams all savings goals, re-emitting whenever the data changes.
class WatchGoals extends StreamUseCase<List<SavingsGoal>, NoParams> {
  const WatchGoals(this._repository);

  final SavingsGoalRepository _repository;

  @override
  ResultStream<List<SavingsGoal>> call(NoParams params) =>
      _repository.watchGoals();
}
