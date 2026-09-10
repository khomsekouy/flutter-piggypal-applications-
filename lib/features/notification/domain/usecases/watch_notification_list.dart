import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/notification/domain/entities/notification.dart';
import 'package:flutter_piggypal_app/features/notification/domain/repositories/notification_repository.dart';

/// Streams all notification items, re-emitting on any change.
class WatchNotificationList
    extends StreamUseCase<List<AppNotification>, NoParams> {
  const WatchNotificationList(this._repository);

  final NotificationRepository _repository;

  @override
  ResultStream<List<AppNotification>> call(NoParams params) =>
      _repository.watchAll();
}
