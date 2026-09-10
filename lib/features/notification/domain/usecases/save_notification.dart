import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/notification/domain/entities/notification.dart';
import 'package:flutter_piggypal_app/features/notification/domain/repositories/notification_repository.dart';

class SaveNotification
    extends UseCase<AppNotification, SaveNotificationParams> {
  const SaveNotification(this._repository);

  final NotificationRepository _repository;

  @override
  ResultFuture<AppNotification> call(SaveNotificationParams params) =>
      _repository.save(params.item);
}

class SaveNotificationParams extends Equatable {
  const SaveNotificationParams(this.item);

  final AppNotification item;

  @override
  List<Object?> get props => [item];
}
