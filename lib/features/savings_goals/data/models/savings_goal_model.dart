import 'package:drift/drift.dart';
import 'package:flutter_piggypal_app/core/database/app_database.dart';
import 'package:flutter_piggypal_app/features/savings_goals/domain/entities/savings_goal.dart';

/// Data-layer representation of a [SavingsGoal].
///
/// Extends the domain entity and adds the mapping to/from Drift rows. The
/// domain layer never sees this class — repositories return entities.
class SavingsGoalModel extends SavingsGoal {
  const SavingsGoalModel({
    required super.id,
    required super.name,
    required super.targetAmount,
    required super.createdAt,
    super.currentAmount,
    super.deadline,
    super.colorValue,
    super.iconName,
  });

  /// Builds a model from a generated Drift row.
  factory SavingsGoalModel.fromRow(SavingsGoalRow row) {
    return SavingsGoalModel(
      id: row.id,
      name: row.name,
      targetAmount: row.targetAmount,
      currentAmount: row.currentAmount,
      deadline: row.deadline,
      colorValue: row.colorValue,
      iconName: row.iconName,
      createdAt: row.createdAt,
    );
  }

  /// Widens any [SavingsGoal] into a model so it can be persisted.
  factory SavingsGoalModel.fromEntity(SavingsGoal goal) {
    return SavingsGoalModel(
      id: goal.id,
      name: goal.name,
      targetAmount: goal.targetAmount,
      currentAmount: goal.currentAmount,
      deadline: goal.deadline,
      colorValue: goal.colorValue,
      iconName: goal.iconName,
      createdAt: goal.createdAt,
    );
  }

  /// Converts to a Drift companion for inserts/updates.
  SavingsGoalsCompanion toCompanion() {
    return SavingsGoalsCompanion(
      id: Value(id),
      name: Value(name),
      targetAmount: Value(targetAmount),
      currentAmount: Value(currentAmount),
      deadline: Value(deadline),
      colorValue: Value(colorValue),
      iconName: Value(iconName),
      createdAt: Value(createdAt),
    );
  }
}
