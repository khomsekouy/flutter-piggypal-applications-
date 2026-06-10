import 'package:flutter_piggypal_app/features/more/data/models/more_model.dart';

/// Local (Drift) data source for the more feature.
///
/// Throws on failure; the repository maps exceptions to `Failure`s.
abstract interface class MoreLocalDataSource {
  Future<List<MoreModel>> getAll();
  Stream<List<MoreModel>> watchAll();
  Future<MoreModel> save(MoreModel item);
  Future<void> delete(String id);
}

class MoreLocalDataSourceImpl implements MoreLocalDataSource {
  const MoreLocalDataSourceImpl();

  // TODO(khomsekouy): inject AppDatabase and replace these stubs with real
  // Drift queries. See features/transactions for a worked example.

  @override
  Future<List<MoreModel>> getAll() async => <MoreModel>[];

  @override
  Stream<List<MoreModel>> watchAll() =>
      Stream<List<MoreModel>>.value(<MoreModel>[]);

  @override
  Future<MoreModel> save(MoreModel item) async => item;

  @override
  Future<void> delete(String id) async {}
}
