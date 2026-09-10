import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/notification/domain/entities/notification.dart';

/// Domain contract for the notification feature.
///
/// The data layer provides the implementation.
abstract interface class NotificationRepository {
  ResultFuture<List<AppNotification>> getAll();

  ResultStream<List<AppNotification>> watchAll();

  ResultFuture<AppNotification> save(AppNotification item);

  ResultVoid delete(String id);

  /// Marks one item read. A no-op when it is already read or gone.
  ResultVoid markRead(String id);

  /// Marks everything read in one statement, rather than a write per row.
  ResultVoid markAllRead();
}
