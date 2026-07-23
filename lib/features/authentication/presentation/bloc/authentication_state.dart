part of 'authentication_bloc.dart';

enum AuthenticationStatus { initial, loading, success, failure }

class AuthenticationState extends Equatable {
  const AuthenticationState({
    this.status = AuthenticationStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  final AuthenticationStatus status;
  final List<Authentication> items;
  final String? errorMessage;

  AuthenticationState copyWith({
    AuthenticationStatus? status,
    List<Authentication>? items,
    String? errorMessage,
  }) {
    return AuthenticationState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage];
}
