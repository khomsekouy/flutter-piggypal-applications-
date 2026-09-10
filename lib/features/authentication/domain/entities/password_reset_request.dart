import 'package:equatable/equatable.dart';

/// What asking for a password-reset code came back with.
///
/// Deliberately says nothing about whether the number has an account: the
/// server answers a registered and an unknown number identically, so that
/// this endpoint cannot be used to find out which numbers are registered.
/// There is nothing here to branch on, and that is the point.
///
/// [devCode] is the one exception, and only against a server running with
/// mocked codes — see [PasswordResetRequest.devCode].
class PasswordResetRequest extends Equatable {
  const PasswordResetRequest({this.devCode});

  /// The issued code, echoed back only by a server with mocked codes, and
  /// only when the number really did have an account behind it.
  ///
  /// Null against any server that means it — the code goes out by SMS there.
  /// Shown in debug builds so the flow can be walked without an SMS provider,
  /// which the API still does not have.
  final String? devCode;

  @override
  List<Object?> get props => [devCode];
}
