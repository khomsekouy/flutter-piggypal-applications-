import 'package:drift/drift.dart';
import 'package:flutter_piggypal_app/core/database/app_database.dart';
import 'package:flutter_piggypal_app/core/error/exceptions.dart';
import 'package:flutter_piggypal_app/features/transactions/data/models/transaction_model.dart';

/// Talks to the local Drift database for transactions.
///
/// Throws [DatabaseException] on failure; the repository maps these to
/// `Failure`s.
abstract interface class TransactionLocalDataSource {
  Future<List<TransactionModel>> getTransactions();
  Stream<List<TransactionModel>> watchTransactions();
  Future<TransactionModel> upsertTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
}

class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  const TransactionLocalDataSourceImpl(this._db);

  final AppDatabase _db;

  // Newest first: by transaction date, then insertion time as a tiebreaker.
  List<OrderingTerm Function($TransactionsTable)> get _ordering => [
        (t) => OrderingTerm.desc(t.date),
        (t) => OrderingTerm.desc(t.createdAt),
      ];

  @override
  Future<List<TransactionModel>> getTransactions() async {
    try {
      final rows =
          await (_db.select(_db.transactions)..orderBy(_ordering)).get();
      return rows.map(TransactionModel.fromRow).toList();
    } catch (e) {
      throw DatabaseException(e.toString());
    }
  }

  @override
  Stream<List<TransactionModel>> watchTransactions() {
    return (_db.select(_db.transactions)..orderBy(_ordering))
        .watch()
        .map((rows) => rows.map(TransactionModel.fromRow).toList());
  }

  @override
  Future<TransactionModel> upsertTransaction(
    TransactionModel transaction,
  ) async {
    try {
      await _db
          .into(_db.transactions)
          .insertOnConflictUpdate(transaction.toCompanion());
      return transaction;
    } catch (e) {
      throw DatabaseException(e.toString());
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    try {
      await (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
    } catch (e) {
      throw DatabaseException(e.toString());
    }
  }
}
