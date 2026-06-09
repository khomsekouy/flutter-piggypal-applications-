import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_piggypal_app/features/transactions/domain/repositories/transaction_repository.dart';

/// Streams all transactions, re-emitting whenever the data changes.
class WatchTransactions extends StreamUseCase<List<Transaction>, NoParams> {
  const WatchTransactions(this._repository);

  final TransactionRepository _repository;

  @override
  ResultStream<List<Transaction>> call(NoParams params) =>
      _repository.watchTransactions();
}
