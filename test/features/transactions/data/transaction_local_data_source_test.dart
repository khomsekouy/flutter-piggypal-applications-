import 'package:drift/native.dart';
import 'package:flutter_piggypal_app/core/database/app_database.dart';
import 'package:flutter_piggypal_app/features/transactions/data/datasources/transaction_local_data_source.dart';
import 'package:flutter_piggypal_app/features/transactions/data/models/transaction_model.dart';
import 'package:flutter_piggypal_app/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late TransactionLocalDataSourceImpl dataSource;

  TransactionModel model({
    String id = 'tx-1',
    TransactionType type = TransactionType.expense,
    double amount = 50,
  }) =>
      TransactionModel(
        id: id,
        title: 'Coffee',
        amount: amount,
        type: type,
        date: DateTime(2026, 6),
        createdAt: DateTime(2026, 6),
      );

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dataSource = TransactionLocalDataSourceImpl(db);
  });

  tearDown(() => db.close());

  group('TransactionLocalDataSource', () {
    test('upsert then getTransactions returns the stored row', () async {
      await dataSource.upsertTransaction(model());

      final result = await dataSource.getTransactions();

      expect(result, hasLength(1));
      expect(result.first.title, 'Coffee');
      expect(result.first.type, TransactionType.expense);
    });

    test('persists the transaction type across a round-trip', () async {
      await dataSource
          .upsertTransaction(model(type: TransactionType.income));

      final result = await dataSource.getTransactions();

      expect(result.first.type, TransactionType.income);
    });

    test('deleteTransaction removes the row', () async {
      await dataSource.upsertTransaction(model());

      await dataSource.deleteTransaction('tx-1');

      expect(await dataSource.getTransactions(), isEmpty);
    });
  });
}
