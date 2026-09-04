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
    this.notice,
  });

  final AuthenticationStatus status;

  /// The signed-in account, or null when there is no session.
  final AuthUser? user;

  /// Set for one emission after a failed call; the screen shows it and then
  /// dispatches [AuthenticationErrorDismissed].
  final String? errorMessage;

  /// Something worth telling the user that is not a failure — the recovery
  /// window after a deletion, so far.
  ///
  /// Carried across emissions rather than dropped like [errorMessage], and for
  /// a specific reason: the screen that has to show this is not the one that
  /// was mounted when it was set. Deleting an account signs the user out and
  /// lands them on sign-in, which mounts *after* the emission and so would
  /// never see a one-shot message. It is cleared by
  /// [AuthenticationNoticeDismissed] once a screen has actually shown it.
  final String? notice;

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
    String? notice,
    bool clearUser = false,
    bool clearNotice = false,
  }) {
    return AuthenticationState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      // Not carried over: a message is shown once. Anything that wants to keep
      // it has to pass it again.
      errorMessage: errorMessage,
      // Carried, unlike the above — see [notice].
      notice: clearNotice ? null : (notice ?? this.notice),
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage, notice];
}
