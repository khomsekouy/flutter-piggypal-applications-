import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/error/failures.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/features/notification/domain/entities/notification.dart';
import 'package:flutter_piggypal_app/features/notification/domain/usecases/delete_notification.dart';
import 'package:flutter_piggypal_app/features/notification/domain/usecases/mark_all_notifications_read.dart';
import 'package:flutter_piggypal_app/features/notification/domain/usecases/mark_notification_read.dart';
import 'package:flutter_piggypal_app/features/notification/domain/usecases/save_notification.dart';
import 'package:flutter_piggypal_app/features/notification/domain/usecases/watch_notification_list.dart';
import 'package:fpdart/fpdart.dart';

part 'notification_event.dart';
part 'notification_state.dart';

/// Drives the notification use cases for the UI.
///
/// The list stays fresh via a live Drift stream, so writes never need a manual
/// refresh — every handler below just writes and lets the stream re-emit.
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc({
    required WatchNotificationList watchNotificationList,
    required DeleteNotification deleteNotification,
    required SaveNotification saveNotification,
    required MarkNotificationRead markNotificationRead,
    required MarkAllNotificationsRead markAllNotificationsRead,
  }) : _watchNotificationList = watchNotificationList,
       _deleteNotification = deleteNotification,
       _saveNotification = saveNotification,
       _markNotificationRead = markNotificationRead,
       _markAllNotificationsRead = markAllNotificationsRead,
       super(const NotificationState()) {
    on<NotificationSubscriptionRequested>(_onSubscriptionRequested);
    on<NotificationDeleted>(_onDeleted);
    on<NotificationRestored>(_onRestored);
    on<NotificationRead>(_onRead);
    on<NotificationAllRead>(_onAllRead);
  }

  final WatchNotificationList _watchNotificationList;
  final DeleteNotification _deleteNotification;
  final SaveNotification _saveNotification;
  final MarkNotificationRead _markNotificationRead;
  final MarkAllNotificationsRead _markAllNotificationsRead;

  Future<void> _onSubscriptionRequested(
    NotificationSubscriptionRequested event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(status: NotificationStatus.loading));
    await emit.forEach<List<AppNotification>>(
      _watchNotificationList(const NoParams()),
      onData: (items) =>
          state.copyWith(status: NotificationStatus.success, items: items),
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
    _emitFailure(result, emit);
  }

  /// Undo for a swipe-away. The row carries its own `receivedAt`, so writing
  /// it back is enough to put it where it was — the list is ordered by time,
  /// not by insertion.
  Future<void> _onRestored(
    NotificationRestored event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await _saveNotification(
      SaveNotificationParams(event.item),
    );
    _emitFailure(result, emit);
  }

  Future<void> _onRead(
    NotificationRead event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await _markNotificationRead(
      MarkNotificationReadParams(event.id),
    );
    _emitFailure(result, emit);
  }

  Future<void> _onAllRead(
    NotificationAllRead event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await _markAllNotificationsRead(const NoParams());
    _emitFailure(result, emit);
  }

  /// Surfaces a write failure without touching [NotificationState.items] —
  /// the stream owns the list, and a failed write simply never changed it.
  void _emitFailure<T>(
    Either<Failure, T> result,
    Emitter<NotificationState> emit,
  ) {
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
