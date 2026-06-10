import 'package:drift/native.dart';
import 'package:flutter_piggypal_app/core/database/app_database.dart';
import 'package:flutter_piggypal_app/features/savings_goals/data/datasources/savings_goal_local_data_source.dart';
import 'package:flutter_piggypal_app/features/savings_goals/data/models/savings_goal_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SavingsGoalLocalDataSourceImpl dataSource;

  SavingsGoalModel model({double current = 0}) => SavingsGoalModel(
    id: 'goal-1',
    name: 'Laptop',
    targetAmount: 1000,
    currentAmount: current,
    createdAt: DateTime(2026),
  );

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dataSource = SavingsGoalLocalDataSourceImpl(db);
  });

  tearDown(() => db.close());

  group('SavingsGoalLocalDataSource', () {
    test('upsert then getGoals returns the stored goal', () async {
      await dataSource.upsertGoal(model());

      final goals = await dataSource.getGoals();

      expect(goals, hasLength(1));
      expect(goals.first.name, 'Laptop');
      expect(goals.first.targetAmount, 1000);
    });

    test('addContribution increments the saved amount', () async {
      await dataSource.upsertGoal(model());

      final updated = await dataSource.addContribution('goal-1', 250);

      expect(updated.currentAmount, 250);
    });

    test('deleteGoal removes the goal', () async {
      await dataSource.upsertGoal(model());

      await dataSource.deleteGoal('goal-1');

      expect(await dataSource.getGoals(), isEmpty);
    });
  });
}
