import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/transactions/domain/repositories/transaction_repository.dart';

class DeleteTransaction extends UseCase<void, DeleteTransactionParams> {
  const DeleteTransaction(this._repository);

  final TransactionRepository _repository;

  @override
  ResultVoid call(DeleteTransactionParams params) =>
      _repository.deleteTransaction(params.id);
}

class DeleteTransactionParams extends Equatable {
  const DeleteTransactionParams(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
