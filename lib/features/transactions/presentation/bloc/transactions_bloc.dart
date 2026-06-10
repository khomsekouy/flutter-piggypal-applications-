import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_piggypal_app/features/transactions/domain/usecases/add_transaction.dart';
import 'package:flutter_piggypal_app/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:flutter_piggypal_app/features/transactions/domain/usecases/watch_transactions.dart';
import 'package:uuid/uuid.dart';

part 'transactions_event.dart';
part 'transactions_state.dart';

/// Drives the transactions use cases for the UI.
///
/// Like the savings-goals bloc, the list stays fresh via [WatchTransactions] —
/// a live Drift stream — so writes never need a manual refresh.
class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  TransactionsBloc({
    required WatchTransactions watchTransactions,
    required AddTransaction addTransaction,
    required DeleteTransaction deleteTransaction,
    Uuid? uuid,
  }) : _watchTransactions = watchTransactions,
       _addTransaction = addTransaction,
       _deleteTransaction = deleteTransaction,
       _uuid = uuid ?? const Uuid(),
       super(const TransactionsState()) {
    on<TransactionsSubscriptionRequested>(_onSubscriptionRequested);
    on<TransactionAdded>(_onTransactionAdded);
    on<TransactionDeleted>(_onTransactionDeleted);
  }

  final WatchTransactions _watchTransactions;
  final AddTransaction _addTransaction;
  final DeleteTransaction _deleteTransaction;
  final Uuid _uuid;

  Future<void> _onSubscriptionRequested(
    TransactionsSubscriptionRequested event,
    Emitter<TransactionsState> emit,
  ) async {
    emit(state.copyWith(status: TransactionsStatus.loading));
    await emit.forEach<List<Transaction>>(
      _watchTransactions(const NoParams()),
      onData: (transactions) => state.copyWith(
        status: TransactionsStatus.success,
        transactions: transactions,
      ),
      onError: (_, _) => state.copyWith(
        status: TransactionsStatus.failure,
        errorMessage: 'Could not load your transactions.',
      ),
    );
  }

  Future<void> _onTransactionAdded(
    TransactionAdded event,
    Emitter<TransactionsState> emit,
  ) async {
    final transaction = Transaction(
      id: _uuid.v4(),
      title: event.title,
      amount: event.amount,
      type: event.type,
      category: event.category,
      note: event.note,
      date: event.date,
      createdAt: _now(),
    );
    final result = await _addTransaction(AddTransactionParams(transaction));
    result.match(
      (failure) => emit(
        state.copyWith(
          status: TransactionsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      // Success needs no manual emit — the watch stream pushes the new list.
      (_) {},
    );
  }

  Future<void> _onTransactionDeleted(
    TransactionDeleted event,
    Emitter<TransactionsState> emit,
  ) async {
    final result = await _deleteTransaction(DeleteTransactionParams(event.id));
    result.match(
      (failure) => emit(
        state.copyWith(
          status: TransactionsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) {},
    );
  }

  DateTime _now() => DateTime.now();
}
