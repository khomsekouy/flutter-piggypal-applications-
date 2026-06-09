import 'package:equatable/equatable.dart';

/// A savings goal the user is working towards (the "piggy bank").
///
/// This is a pure domain object: no Drift, no JSON, no Flutter. It can be
/// constructed and tested without any infrastructure.
class SavingsGoal extends Equatable {
  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.createdAt,
    this.currentAmount = 0,
    this.deadline,
    this.colorValue = 0xFF8E4DFF,
    this.iconName = 'savings',
  });

  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final int colorValue;
  final String iconName;
  final DateTime createdAt;

  /// Progress in the range `0.0`–`1.0`. Guards against a zero target.
  double get progress {
    if (targetAmount <= 0) return 0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  /// Amount still needed to reach the target (never negative).
  double get remaining =>
      (targetAmount - currentAmount).clamp(0, double.infinity);

  bool get isCompleted => currentAmount >= targetAmount;

  SavingsGoal copyWith({
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    int? colorValue,
    String? iconName,
  }) {
    return SavingsGoal(
      id: id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      colorValue: colorValue ?? this.colorValue,
      iconName: iconName ?? this.iconName,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        targetAmount,
        currentAmount,
        deadline,
        colorValue,
        iconName,
        createdAt,
      ];
}
