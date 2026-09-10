import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/notification/domain/repositories/notification_repository.dart';

/// Marks a single notification read — what tapping a row does.
class MarkNotificationRead extends UseCase<void, MarkNotificationReadParams> {
  const MarkNotificationRead(this._repository);

  final NotificationRepository _repository;

  @override
  ResultVoid call(MarkNotificationReadParams params) =>
      _repository.markRead(params.id);
}

class MarkNotificationReadParams extends Equatable {
  const MarkNotificationReadParams(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
