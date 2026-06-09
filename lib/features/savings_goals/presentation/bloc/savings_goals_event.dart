part of 'savings_goals_bloc.dart';

sealed class SavingsGoalsEvent extends Equatable {
  const SavingsGoalsEvent();

  @override
  List<Object?> get props => [];
}

/// Start listening to the live stream of goals.
class GoalsSubscriptionRequested extends SavingsGoalsEvent {
  const GoalsSubscriptionRequested();
}

class GoalCreated extends SavingsGoalsEvent {
  const GoalCreated({
    required this.name,
    required this.targetAmount,
    this.deadline,
    this.colorValue = AppTheme.seedValue,
    this.iconName = 'savings',
  });

  final String name;
  final double targetAmount;
  final DateTime? deadline;
  final int colorValue;
  final String iconName;

  @override
  List<Object?> get props =>
      [name, targetAmount, deadline, colorValue, iconName];
}

class ContributionAdded extends SavingsGoalsEvent {
  const ContributionAdded({required this.goalId, required this.amount});

  final String goalId;
  final double amount;

  @override
  List<Object?> get props => [goalId, amount];
}

class GoalDeleted extends SavingsGoalsEvent {
  const GoalDeleted(this.goalId);

  final String goalId;

  @override
  List<Object?> get props => [goalId];
}
