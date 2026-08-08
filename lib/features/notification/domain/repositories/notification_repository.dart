import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/notification/domain/entities/notification.dart';

/// Domain contract for the notification feature.
///
/// The data layer provides the implementation.
abstract interface class NotificationRepository {
  ResultFuture<List<Notification>> getAll();

  ResultStream<List<Notification>> watchAll();

  ResultFuture<Notification> save(Notification item);

  ResultVoid delete(String id);
}
