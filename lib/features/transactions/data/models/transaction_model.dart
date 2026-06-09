import 'package:drift/drift.dart';
import 'package:flutter_piggypal_app/core/database/app_database.dart';
import 'package:flutter_piggypal_app/features/transactions/domain/entities/transaction.dart';

/// Data-layer representation of a [Transaction] with Drift row mapping.
///
/// The [TransactionType] enum is persisted by its `name` (`'income'` /
/// `'expense'`) so the stored value stays readable and stable.
class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.title,
    required super.amount,
    required super.type,
    required super.date,
    required super.createdAt,
    super.category,
    super.note,
  });

  factory TransactionModel.fromRow(TransactionRow row) {
    return TransactionModel(
      id: row.id,
      title: row.title,
      amount: row.amount,
      type: _typeFromName(row.type),
      category: row.category,
      note: row.note,
      date: row.date,
      createdAt: row.createdAt,
    );
  }

  factory TransactionModel.fromEntity(Transaction transaction) {
    return TransactionModel(
      id: transaction.id,
      title: transaction.title,
      amount: transaction.amount,
      type: transaction.type,
      category: transaction.category,
      note: transaction.note,
      date: transaction.date,
      createdAt: transaction.createdAt,
    );
  }

  TransactionsCompanion toCompanion() {
    return TransactionsCompanion(
      id: Value(id),
      title: Value(title),
      amount: Value(amount),
      type: Value(type.name),
      category: Value(category),
      note: Value(note),
      date: Value(date),
      createdAt: Value(createdAt),
    );
  }

  static TransactionType _typeFromName(String name) {
    return TransactionType.values.firstWhere(
      (t) => t.name == name,
      orElse: () => TransactionType.expense,
    );
  }
}
