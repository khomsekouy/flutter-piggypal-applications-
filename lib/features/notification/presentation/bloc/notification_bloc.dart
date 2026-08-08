import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/features/notification/domain/entities/notification.dart';
import 'package:flutter_piggypal_app/features/notification/domain/usecases/delete_notification.dart';
import 'package:flutter_piggypal_app/features/notification/domain/usecases/watch_notification_list.dart';

part 'notification_event.dart';
part 'notification_state.dart';

/// Drives the notification use cases for the UI.
///
/// The list stays fresh via a live Drift stream, so writes never need a manual
/// refresh.
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc({
    required WatchNotificationList watchNotificationList,
    required DeleteNotification deleteNotification,
  }) : _watchNotificationList = watchNotificationList,
       _deleteNotification = deleteNotification,
       super(const NotificationState()) {
    on<NotificationSubscriptionRequested>(_onSubscriptionRequested);
    on<NotificationDeleted>(_onDeleted);
  }

  final WatchNotificationList _watchNotificationList;
  final DeleteNotification _deleteNotification;

  Future<void> _onSubscriptionRequested(
    NotificationSubscriptionRequested event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(status: NotificationStatus.loading));
    await emit.forEach<List<Notification>>(
      _watchNotificationList(const NoParams()),
      onData: (items) => state.copyWith(
        status: NotificationStatus.success,
        items: items,
      ),
      onError: (_, _) => state.copyWith(
        status: NotificationStatus.failure,
        errorMessage: 'Could not load data.',
      ),
    );
  }

  Future<void> _onDeleted(
    NotificationDeleted event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await _deleteNotification(
      DeleteNotificationParams(event.id),
    );
    result.match(
      (failure) => emit(
        state.copyWith(
          status: NotificationStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) {},
    );
  }
}
