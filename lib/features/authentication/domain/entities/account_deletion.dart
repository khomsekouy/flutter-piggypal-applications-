import 'package:equatable/equatable.dart';

/// What `POST /auth/delete-account` hands back.
///
/// The account is not gone when this returns — it is soft-deleted, its
/// sessions revoked, and scheduled to be purged. Until [purgeAt] the user can
/// have it back through `POST /auth/restore-account`, which is the only way
/// in: signing in is refused for an account in this state, so the app has to
/// offer the recovery path explicitly or the window may as well not exist.
class AccountDeletion extends Equatable {
  const AccountDeletion({this.purgeAt, this.message});

  /// When the account stops being recoverable. Nullable because a date the
  /// server did not send, or sent unparseably, must not become a promise: the
  /// UI says "you can recover it" without naming a day rather than naming the
  /// wrong one.
  final DateTime? purgeAt;

  /// The server's own wording ("Account scheduled for deletion").
  final String? message;

  @override
  List<Object?> get props => [purgeAt, message];
}
