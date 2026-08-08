part of 'notification_bloc.dart';

enum NotificationStatus { initial, loading, success, failure }

class NotificationState extends Equatable {
  const NotificationState({
    this.status = NotificationStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  final NotificationStatus status;
  final List<Notification> items;
  final String? errorMessage;

  NotificationState copyWith({
    NotificationStatus? status,
    List<Notification>? items,
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
