import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/transactions/domain/entities/transaction.dart';

/// Domain contract for persisting and reading transactions.
abstract interface class TransactionRepository {
  /// One-shot read of all transactions, newest first.
  ResultFuture<List<Transaction>> getTransactions();

  /// Live stream of all transactions — re-emits on any change.
  ResultStream<List<Transaction>> watchTransactions();

  ResultFuture<Transaction> addTransaction(Transaction transaction);

  ResultVoid deleteTransaction(String id);
}
