import 'package:drift/drift.dart';

/// Drift table definition for savings goals.
///
/// The generated data class is named `SavingsGoalRow` (via [DataClassName]) so
/// it does not collide with the domain entity `SavingsGoal`.
@DataClassName('SavingsGoalRow')
class SavingsGoals extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  RealColumn get targetAmount => real()();
  RealColumn get currentAmount => real().withDefault(const Constant(0))();
  DateTimeColumn get deadline => dateTime().nullable()();
  IntColumn get colorValue =>
      integer().withDefault(const Constant(0xFF8E4DFF))();
  TextColumn get iconName =>
      text().withDefault(const Constant('savings'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
