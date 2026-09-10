import 'package:drift/drift.dart';
import 'package:flutter_piggypal_app/core/database/app_database.dart';
import 'package:flutter_piggypal_app/core/error/exceptions.dart';
import 'package:flutter_piggypal_app/features/notification/data/models/notification_model.dart';

/// Talks to the local Drift database for the notification centre.
///
/// Throws [DatabaseException] on failure; the repository turns these into
/// `Failure`s.
abstract interface class NotificationLocalDataSource {
  Future<List<NotificationModel>> getAll();
  Stream<List<NotificationModel>> watchAll();
  Future<NotificationModel> save(NotificationModel item);
  Future<void> delete(String id);
  Future<void> markRead(String id);
  Future<void> markAllRead();
}

class NotificationLocalDataSourceImpl implements NotificationLocalDataSource {
  const NotificationLocalDataSourceImpl(this._db);

  final AppDatabase _db;

  /// Newest first — the order the screen renders in, and what the day
  /// grouping assumes.
  SimpleSelectStatement<$NotificationsTable, NotificationRow>
  get _newestFirst =>
      _db.select(_db.notifications)
        ..orderBy([(t) => OrderingTerm.desc(t.receivedAt)]);

  @override
  Future<List<NotificationModel>> getAll() async {
    try {
      final rows = await _newestFirst.get();
      return rows.map(NotificationModel.fromRow).toList();
    } catch (e) {
      throw DatabaseException(e.toString());
    }
  }

  @override
  Stream<List<NotificationModel>> watchAll() => _newestFirst.watch().map(
    (rows) => rows.map(NotificationModel.fromRow).toList(),
  );

  @override
  Future<NotificationModel> save(NotificationModel item) async {
    try {
      await _db
          .into(_db.notifications)
          .insertOnConflictUpdate(item.toCompanion());
      return item;
    } catch (e) {
      throw DatabaseException(e.toString());
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await (_db.delete(_db.notifications)..where((t) => t.id.equals(id))).go();
    } catch (e) {
      throw DatabaseException(e.toString());
    }
  }

  @override
  Future<void> markRead(String id) async {
    try {
      await (_db.update(_db.notifications)..where((t) => t.id.equals(id)))
          .write(const NotificationsCompanion(isRead: Value(true)));
    } catch (e) {
      throw DatabaseException(e.toString());
    }
  }

  @override
  Future<void> markAllRead() async {
    try {
      // One statement for the lot, and scoped to the unread rows so the query
      // stream does not re-emit when there is nothing to change.
      await (_db.update(_db.notifications)
            ..where((t) => t.isRead.equals(false)))
          .write(const NotificationsCompanion(isRead: Value(true)));
    } catch (e) {
      throw DatabaseException(e.toString());
    }
  }
}
