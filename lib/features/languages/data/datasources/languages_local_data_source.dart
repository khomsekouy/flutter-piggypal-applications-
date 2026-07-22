import 'package:flutter_piggypal_app/features/languages/data/models/languages_model.dart';

/// Local (Drift) data source for the languages feature.
///
/// Throws on failure; the repository maps exceptions to `Failure`s.
abstract interface class LanguagesLocalDataSource {
  Future<List<LanguagesModel>> getAll();
  Stream<List<LanguagesModel>> watchAll();
  Future<LanguagesModel> save(LanguagesModel item);
  Future<void> delete(String id);
}

class LanguagesLocalDataSourceImpl implements LanguagesLocalDataSource {
  const LanguagesLocalDataSourceImpl();

  // TODO(khomsekouy): inject AppDatabase and replace these stubs with real
  // Drift queries. See features/transactions for a worked example.

  @override
  Future<List<LanguagesModel>> getAll() async => <LanguagesModel>[];

  @override
  Stream<List<LanguagesModel>> watchAll() =>
      Stream<List<LanguagesModel>>.value(<LanguagesModel>[]);

  @override
  Future<LanguagesModel> save(LanguagesModel item) async => item;

  @override
  Future<void> delete(String id) async {}
}
