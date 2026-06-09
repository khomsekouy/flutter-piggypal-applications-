import 'package:drift/drift.dart';
import 'package:flutter_piggypal_app/core/database/app_database.dart';
import 'package:flutter_piggypal_app/core/error/exceptions.dart';
import 'package:flutter_piggypal_app/features/savings_goals/data/models/savings_goal_model.dart';

/// Talks to the local Drift database for savings goals.
///
/// Throws [DatabaseException] / [NotFoundException] on failure — the repository
/// is responsible for turning these into `Failure`s.
abstract interface class SavingsGoalLocalDataSource {
  Future<List<SavingsGoalModel>> getGoals();
  Stream<List<SavingsGoalModel>> watchGoals();
  Future<SavingsGoalModel> upsertGoal(SavingsGoalModel goal);
  Future<SavingsGoalModel> addContribution(String goalId, double amount);
  Future<void> deleteGoal(String goalId);
}

class SavingsGoalLocalDataSourceImpl implements SavingsGoalLocalDataSource {
  const SavingsGoalLocalDataSourceImpl(this._db);

  final AppDatabase _db;

  @override
  Future<List<SavingsGoalModel>> getGoals() async {
    try {
      final rows = await (_db.select(_db.savingsGoals)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();
      return rows.map(SavingsGoalModel.fromRow).toList();
    } catch (e) {
      throw DatabaseException(e.toString());
    }
  }

  @override
  Stream<List<SavingsGoalModel>> watchGoals() {
    return (_db.select(_db.savingsGoals)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map(SavingsGoalModel.fromRow).toList());
  }

  @override
  Future<SavingsGoalModel> upsertGoal(SavingsGoalModel goal) async {
    try {
      await _db
          .into(_db.savingsGoals)
          .insertOnConflictUpdate(goal.toCompanion());
      return goal;
    } catch (e) {
      throw DatabaseException(e.toString());
    }
  }

  @override
  Future<SavingsGoalModel> addContribution(
    String goalId,
    double amount,
  ) async {
    // Read-modify-write inside a transaction so the balance can't race.
    return _db.transaction(() async {
      final row = await (_db.select(_db.savingsGoals)
            ..where((t) => t.id.equals(goalId)))
          .getSingleOrNull();
      if (row == null) {
        throw const NotFoundException('Savings goal not found.');
      }
      final updated = SavingsGoalModel.fromRow(row).copyWith(
        currentAmount: row.currentAmount + amount,
      );
      await _db
          .update(_db.savingsGoals)
          .replace(SavingsGoalModel.fromEntity(updated).toCompanion());
      return SavingsGoalModel.fromEntity(updated);
    });
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    try {
      await (_db.delete(_db.savingsGoals)..where((t) => t.id.equals(goalId)))
          .go();
    } catch (e) {
      throw DatabaseException(e.toString());
    }
  }
}
