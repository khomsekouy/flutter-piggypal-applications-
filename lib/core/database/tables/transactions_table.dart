import 'package:drift/drift.dart';

/// Drift table for money movements (income & expenses).
///
/// [amount] is always stored as a positive number; [type] (`'income'` /
/// `'expense'`) gives it direction. The generated data class is
/// `TransactionRow` so it doesn't collide with the domain `Transaction`.
@DataClassName('TransactionRow')
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  RealColumn get amount => real()();
  TextColumn get type => text()();
  TextColumn get category => text().withDefault(const Constant('General'))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
