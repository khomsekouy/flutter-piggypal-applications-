import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/notification/domain/repositories/notification_repository.dart';

class DeleteNotification extends UseCase<void, DeleteNotificationParams> {
  const DeleteNotification(this._repository);

  final NotificationRepository _repository;

  @override
  ResultVoid call(DeleteNotificationParams params) =>
      _repository.delete(params.id);
}

class DeleteNotificationParams extends Equatable {
  const DeleteNotificationParams(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
