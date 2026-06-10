part of 'programs_bloc.dart';

sealed class ProgramsEvent extends Equatable {
  const ProgramsEvent();

  @override
  List<Object?> get props => [];
}

/// Start listening to the live stream of items.
class ProgramsSubscriptionRequested extends ProgramsEvent {
  const ProgramsSubscriptionRequested();
}

class ProgramsDeleted extends ProgramsEvent {
  const ProgramsDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
