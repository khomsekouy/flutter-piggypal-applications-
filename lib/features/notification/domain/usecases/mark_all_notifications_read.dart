import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/notification/domain/repositories/notification_repository.dart';

/// Clears the whole unread count in one go — the header's "done all" action.
class MarkAllNotificationsRead extends UseCase<void, NoParams> {
  const MarkAllNotificationsRead(this._repository);

  final NotificationRepository _repository;

  @override
  ResultVoid call(NoParams params) => _repository.markAllRead();
}
