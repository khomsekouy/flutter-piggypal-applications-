import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/theme/app_theme.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/features/savings_goals/domain/entities/savings_goal.dart';
import 'package:flutter_piggypal_app/features/savings_goals/domain/usecases/add_contribution.dart';
import 'package:flutter_piggypal_app/features/savings_goals/domain/usecases/create_goal.dart';
import 'package:flutter_piggypal_app/features/savings_goals/domain/usecases/delete_goal.dart';
import 'package:flutter_piggypal_app/features/savings_goals/domain/usecases/watch_goals.dart';
import 'package:uuid/uuid.dart';

part 'savings_goals_event.dart';
part 'savings_goals_state.dart';

/// Orchestrates the savings-goals use cases for the UI.
///
/// It owns no persistence logic itself — it just calls use cases and maps their
/// `Either` results onto states. The list is kept fresh via [WatchGoals], so
/// writes don't need to manually refresh; the stream re-emits.
class SavingsGoalsBloc extends Bloc<SavingsGoalsEvent, SavingsGoalsState> {
  SavingsGoalsBloc({
    required WatchGoals watchGoals,
    required CreateGoal createGoal,
    required AddContribution addContribution,
    required DeleteGoal deleteGoal,
    Uuid? uuid,
  }) : _watchGoals = watchGoals,
       _createGoal = createGoal,
       _addContribution = addContribution,
       _deleteGoal = deleteGoal,
       _uuid = uuid ?? const Uuid(),
       super(const SavingsGoalsState()) {
    on<GoalsSubscriptionRequested>(_onSubscriptionRequested);
    on<GoalCreated>(_onGoalCreated);
    on<ContributionAdded>(_onContributionAdded);
    on<GoalDeleted>(_onGoalDeleted);
  }

  final WatchGoals _watchGoals;
  final CreateGoal _createGoal;
  final AddContribution _addContribution;
  final DeleteGoal _deleteGoal;
  final Uuid _uuid;

  Future<void> _onSubscriptionRequested(
    GoalsSubscriptionRequested event,
    Emitter<SavingsGoalsState> emit,
  ) async {
    emit(state.copyWith(status: SavingsGoalsStatus.loading));
    await emit.forEach<List<SavingsGoal>>(
      _watchGoals(const NoParams()),
      onData: (goals) => state.copyWith(
        status: SavingsGoalsStatus.success,
        goals: goals,
      ),
      onError: (_, _) => state.copyWith(
        status: SavingsGoalsStatus.failure,
        errorMessage: 'Could not load your goals.',
      ),
    );
  }

  Future<void> _onGoalCreated(
    GoalCreated event,
    Emitter<SavingsGoalsState> emit,
  ) async {
    final goal = SavingsGoal(
      id: _uuid.v4(),
      name: event.name,
      targetAmount: event.targetAmount,
      deadline: event.deadline,
      colorValue: event.colorValue,
      iconName: event.iconName,
      createdAt: _now(),
    );
    final result = await _createGoal(CreateGoalParams(goal));
    result.match(
      (failure) => emit(
        state.copyWith(
          status: SavingsGoalsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      // Success needs no manual emit — the watch stream pushes the new list.
      (_) {},
    );
  }

  Future<void> _onContributionAdded(
    ContributionAdded event,
    Emitter<SavingsGoalsState> emit,
  ) async {
    final result = await _addContribution(
      AddContributionParams(goalId: event.goalId, amount: event.amount),
    );
    result.match(
      (failure) => emit(
        state.copyWith(
          status: SavingsGoalsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) {},
    );
  }

  Future<void> _onGoalDeleted(
    GoalDeleted event,
    Emitter<SavingsGoalsState> emit,
  ) async {
    final result = await _deleteGoal(DeleteGoalParams(event.goalId));
    result.match(
      (failure) => emit(
        state.copyWith(
          status: SavingsGoalsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) {},
    );
  }

  // Wrapped so tests can override the clock if needed.
  DateTime _now() => DateTime.now();
}
