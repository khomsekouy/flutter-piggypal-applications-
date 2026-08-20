part of 'authentication_bloc.dart';

enum AuthenticationStatus {
  /// Launch check has not finished — the splash screen waits on this.
  unknown,

  /// A request is in flight.
  loading,
  authenticated,
  unauthenticated,
}

class AuthenticationState extends Equatable {
  const AuthenticationState({
    this.status = AuthenticationStatus.unknown,
    this.user,
    this.errorMessage,
  });

  final AuthenticationStatus status;

  /// The signed-in account, or null when there is no session.
  final AuthUser? user;

  /// Set for one emission after a failed call; the screen shows it and then
  /// dispatches [AuthenticationErrorDismissed].
  final String? errorMessage;

  bool get isBusy => status == AuthenticationStatus.loading;
  bool get isAuthenticated => status == AuthenticationStatus.authenticated;

  /// The launch check has landed on an answer — what the splash screen waits
  /// for before deciding where to send the user.
  bool get isResolved =>
      status == AuthenticationStatus.authenticated ||
      status == AuthenticationStatus.unauthenticated;

  /// [clearUser] exists because `user: null` cannot mean "remove it" in a
  /// `copyWith` — the null is indistinguishable from "leave it alone".
  AuthenticationState copyWith({
    AuthenticationStatus? status,
    AuthUser? user,
    String? errorMessage,
    bool clearUser = false,
  }) {
    return AuthenticationState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      // Not carried over: a message is shown once. Anything that wants to keep
      // it has to pass it again.
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage];
}
