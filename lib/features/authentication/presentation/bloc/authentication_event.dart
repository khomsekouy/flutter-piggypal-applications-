part of 'authentication_bloc.dart';

sealed class AuthenticationEvent extends Equatable {
  const AuthenticationEvent();

  @override
  List<Object?> get props => [];
}

/// Start listening to the live stream of items.
class AuthenticationSubscriptionRequested extends AuthenticationEvent {
  const AuthenticationSubscriptionRequested();
}

class AuthenticationDeleted extends AuthenticationEvent {
  const AuthenticationDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
