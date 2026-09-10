part of 'notification_bloc.dart';

sealed class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

/// Start listening to the live stream of items.
class NotificationSubscriptionRequested extends NotificationEvent {
  const NotificationSubscriptionRequested();
}

class NotificationDeleted extends NotificationEvent {
  const NotificationDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

/// Puts a deleted item back — the undo on the delete snackbar. Carries the
/// whole row, since by then it is gone from the database.
class NotificationRestored extends NotificationEvent {
  const NotificationRestored(this.item);

  final AppNotification item;

  @override
  List<Object?> get props => [item];
}

class NotificationRead extends NotificationEvent {
  const NotificationRead(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class NotificationAllRead extends NotificationEvent {
  const NotificationAllRead();
}
