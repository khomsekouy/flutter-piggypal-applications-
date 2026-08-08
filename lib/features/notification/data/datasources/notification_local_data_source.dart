import 'package:flutter_piggypal_app/features/notification/data/models/notification_model.dart';

/// Local (Drift) data source for the notification feature.
///
/// Throws on failure; the repository maps exceptions to `Failure`s.
abstract interface class NotificationLocalDataSource {
  Future<List<NotificationModel>> getAll();
  Stream<List<NotificationModel>> watchAll();
  Future<NotificationModel> save(NotificationModel item);
  Future<void> delete(String id);
}

class NotificationLocalDataSourceImpl implements NotificationLocalDataSource {
  const NotificationLocalDataSourceImpl();

  // TODO(khomsekouy): inject AppDatabase and replace these stubs with real
  // Drift queries. See features/transactions for a worked example.

  @override
  Future<List<NotificationModel>> getAll() async => <NotificationModel>[];

  @override
  Stream<List<NotificationModel>> watchAll() =>
      Stream<List<NotificationModel>>.value(<NotificationModel>[]);

  @override
  Future<NotificationModel> save(NotificationModel item) async => item;

  @override
  Future<void> delete(String id) async {}
}
