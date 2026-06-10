import 'package:flutter_piggypal_app/features/reports/data/models/reports_model.dart';

/// Local (Drift) data source for the reports feature.
///
/// Throws on failure; the repository maps exceptions to `Failure`s.
abstract interface class ReportsLocalDataSource {
  Future<List<ReportsModel>> getAll();
  Stream<List<ReportsModel>> watchAll();
  Future<ReportsModel> save(ReportsModel item);
  Future<void> delete(String id);
}

class ReportsLocalDataSourceImpl implements ReportsLocalDataSource {
  const ReportsLocalDataSourceImpl();

  // TODO(khomsekouy): inject AppDatabase and replace these stubs with real
  // Drift queries. See features/transactions for a worked example.

  @override
  Future<List<ReportsModel>> getAll() async => <ReportsModel>[];

  @override
  Stream<List<ReportsModel>> watchAll() =>
      Stream<List<ReportsModel>>.value(<ReportsModel>[]);

  @override
  Future<ReportsModel> save(ReportsModel item) async => item;

  @override
  Future<void> delete(String id) async {}
}
