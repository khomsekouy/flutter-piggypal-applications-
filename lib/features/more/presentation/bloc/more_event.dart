part of 'more_bloc.dart';

sealed class MoreEvent extends Equatable {
  const MoreEvent();

  @override
  List<Object?> get props => [];
}

/// Start listening to the live stream of items.
class MoreSubscriptionRequested extends MoreEvent {
  const MoreSubscriptionRequested();
}

class MoreDeleted extends MoreEvent {
  const MoreDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
