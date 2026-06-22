import 'package:flutter_piggypal_app/core/di/injection_container.dart';
import 'package:flutter_piggypal_app/features/transactions/data/datasources/transaction_local_data_source.dart';
import 'package:flutter_piggypal_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:flutter_piggypal_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter_piggypal_app/features/transactions/domain/usecases/add_transaction.dart';
import 'package:flutter_piggypal_app/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:flutter_piggypal_app/features/transactions/domain/usecases/watch_transactions.dart';
import 'package:flutter_piggypal_app/features/transactions/presentation/bloc/transactions_bloc.dart';

/// Wires the transactions feature into the service locator.
/// Called once from [initDependencies].
void initTransactions() {
  sl
    // Bloc — fresh per screen.
    ..registerFactory(
      () => TransactionsBloc(
        watchTransactions: sl(),
        addTransaction: sl(),
        deleteTransaction: sl(),
      ),
    )
    // Use cases.
    ..registerLazySingleton(() => WatchTransactions(sl()))
    ..registerLazySingleton(() => AddTransaction(sl()))
    ..registerLazySingleton(() => DeleteTransaction(sl()))
    // Repository.
    ..registerLazySingleton<TransactionRepository>(
      () => TransactionRepositoryImpl(sl()),
    )
    // Data source.
    ..registerLazySingleton<TransactionLocalDataSource>(
      () => TransactionLocalDataSourceImpl(sl()),
    );
}
