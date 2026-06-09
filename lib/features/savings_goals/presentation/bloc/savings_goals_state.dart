part of 'savings_goals_bloc.dart';

enum SavingsGoalsStatus { initial, loading, success, failure }

class SavingsGoalsState extends Equatable {
  const SavingsGoalsState({
    this.status = SavingsGoalsStatus.initial,
    this.goals = const [],
    this.errorMessage,
  });

  final SavingsGoalsStatus status;
  final List<SavingsGoal> goals;
  final String? errorMessage;

  /// Combined target across every goal.
  double get totalTarget =>
      goals.fold(0, (sum, g) => sum + g.targetAmount);

  /// Combined saved balance across every goal.
  double get totalSaved =>
      goals.fold(0, (sum, g) => sum + g.currentAmount);

  SavingsGoalsState copyWith({
    SavingsGoalsStatus? status,
    List<SavingsGoal>? goals,
    String? errorMessage,
  }) {
    return SavingsGoalsState(
      status: status ?? this.status,
      goals: goals ?? this.goals,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, goals, errorMessage];
}
