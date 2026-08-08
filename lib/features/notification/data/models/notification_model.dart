import 'package:flutter_piggypal_app/features/notification/domain/entities/notification.dart';

/// Data-layer representation of [Notification].
///
/// Once you add the Drift table, give this a `fromRow(...)` factory and a
/// `toCompanion()` method (see features/transactions for a worked example).
class NotificationModel extends Notification {
  const NotificationModel({required super.id, required super.name});

  factory NotificationModel.fromEntity(Notification entity) =>
      NotificationModel(id: entity.id, name: entity.name);
}
