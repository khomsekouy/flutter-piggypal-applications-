import 'package:flutter_piggypal_app/features/authentication/data/models/authentication_model.dart';

/// Local (Drift) data source for the authentication feature.
///
/// Throws on failure; the repository maps exceptions to `Failure`s.
abstract interface class AuthenticationLocalDataSource {
  Future<List<AuthenticationModel>> getAll();
  Stream<List<AuthenticationModel>> watchAll();
  Future<AuthenticationModel> save(AuthenticationModel item);
  Future<void> delete(String id);
}

class AuthenticationLocalDataSourceImpl
    implements AuthenticationLocalDataSource {
  const AuthenticationLocalDataSourceImpl();

  // TODO(khomsekouy): inject AppDatabase and replace these stubs with real
  // Drift queries. See features/transactions for a worked example.

  @override
  Future<List<AuthenticationModel>> getAll() async => <AuthenticationModel>[];

  @override
  Stream<List<AuthenticationModel>> watchAll() =>
      Stream<List<AuthenticationModel>>.value(<AuthenticationModel>[]);

  @override
  Future<AuthenticationModel> save(AuthenticationModel item) async => item;

  @override
  Future<void> delete(String id) async {}
}
