import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_piggypal_app/features/transactions/domain/repositories/transaction_repository.dart';

class AddTransaction extends UseCase<Transaction, AddTransactionParams> {
  const AddTransaction(this._repository);

  final TransactionRepository _repository;

  @override
  ResultFuture<Transaction> call(AddTransactionParams params) =>
      _repository.addTransaction(params.transaction);
}

class AddTransactionParams extends Equatable {
  const AddTransactionParams(this.transaction);

  final Transaction transaction;

  @override
  List<Object?> get props => [transaction];
}
