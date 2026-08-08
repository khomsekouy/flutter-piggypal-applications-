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
