part of 'languages_bloc.dart';

sealed class LanguagesEvent extends Equatable {
  const LanguagesEvent();

  @override
  List<Object?> get props => [];
}

/// Start listening to the live stream of items.
class LanguagesSubscriptionRequested extends LanguagesEvent {
  const LanguagesSubscriptionRequested();
}

class LanguagesDeleted extends LanguagesEvent {
  const LanguagesDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
