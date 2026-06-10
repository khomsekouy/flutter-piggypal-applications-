import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_piggypal_app/features/transactions/domain/usecases/add_transaction.dart';
import 'package:flutter_piggypal_app/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:flutter_piggypal_app/features/transactions/domain/usecases/watch_transactions.dart';
import 'package:flutter_piggypal_app/features/transactions/presentation/bloc/transactions_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockWatchTransactions extends Mock implements WatchTransactions {}

class _MockAddTransaction extends Mock implements AddTransaction {}

class _MockDeleteTransaction extends Mock implements DeleteTransaction {}

void main() {
  late WatchTransactions watchTransactions;
  late AddTransaction addTransaction;
  late DeleteTransaction deleteTransaction;

  final tx = Transaction(
    id: '1',
    title: 'Coffee',
    amount: 4.5,
    type: TransactionType.expense,
    date: DateTime(2026, 6),
    createdAt: DateTime(2026, 6),
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(AddTransactionParams(tx));
    registerFallbackValue(const DeleteTransactionParams('1'));
  });

  setUp(() {
    watchTransactions = _MockWatchTransactions();
    addTransaction = _MockAddTransaction();
    deleteTransaction = _MockDeleteTransaction();
  });

  TransactionsBloc buildBloc() => TransactionsBloc(
    watchTransactions: watchTransactions,
    addTransaction: addTransaction,
    deleteTransaction: deleteTransaction,
  );

  group('TransactionsBloc', () {
    blocTest<TransactionsBloc, TransactionsState>(
      'emits [loading, success] with transactions from the stream',
      setUp: () {
        when(
          () => watchTransactions(any()),
        ).thenAnswer((_) => Stream.value([tx]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const TransactionsSubscriptionRequested()),
      expect: () => [
        const TransactionsState(status: TransactionsStatus.loading),
        TransactionsState(
          status: TransactionsStatus.success,
          transactions: [tx],
        ),
      ],
    );

    blocTest<TransactionsBloc, TransactionsState>(
      'calls addTransaction use case on TransactionAdded',
      setUp: () {
        when(() => addTransaction(any())).thenAnswer((_) async => Right(tx));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        TransactionAdded(
          title: 'Coffee',
          amount: 4.5,
          type: TransactionType.expense,
          date: DateTime(2026, 6),
        ),
      ),
      verify: (_) => verify(() => addTransaction(any())).called(1),
    );
  });
}
