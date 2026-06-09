import 'package:flutter_piggypal_app/core/error/exceptions.dart';
import 'package:flutter_piggypal_app/core/error/failures.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/transactions/data/datasources/transaction_local_data_source.dart';
import 'package:flutter_piggypal_app/features/transactions/data/models/transaction_model.dart';
import 'package:flutter_piggypal_app/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_piggypal_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Maps the local data source's exceptions onto domain `Failure`s.
class TransactionRepositoryImpl implements TransactionRepository {
  const TransactionRepositoryImpl(this._local);

  final TransactionLocalDataSource _local;

  @override
  ResultFuture<List<Transaction>> getTransactions() async {
    try {
      return Right(await _local.getTransactions());
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  ResultStream<List<Transaction>> watchTransactions() =>
      _local.watchTransactions();

  @override
  ResultFuture<Transaction> addTransaction(Transaction transaction) async {
    try {
      final saved = await _local.upsertTransaction(
        TransactionModel.fromEntity(transaction),
      );
      return Right(saved);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  ResultVoid deleteTransaction(String id) async {
    try {
      await _local.deleteTransaction(id);
      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }
}
