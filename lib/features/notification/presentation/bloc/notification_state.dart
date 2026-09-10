part of 'notification_bloc.dart';

enum NotificationStatus { initial, loading, success, failure }

class NotificationState extends Equatable {
  const NotificationState({
    this.status = NotificationStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  final NotificationStatus status;
  final List<AppNotification> items;
  final String? errorMessage;

  /// What the bell badge and the screen's summary both count.
  int get unreadCount => items.where((n) => !n.read).length;

  NotificationState copyWith({
    NotificationStatus? status,
    List<AppNotification>? items,
    String? errorMessage,
  }) {
    return NotificationState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage];
}
