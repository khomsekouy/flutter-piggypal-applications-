part of 'reports_bloc.dart';

sealed class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object?> get props => [];
}

/// Start listening to the live stream of items.
class ReportsSubscriptionRequested extends ReportsEvent {
  const ReportsSubscriptionRequested();
}

class ReportsDeleted extends ReportsEvent {
  const ReportsDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
