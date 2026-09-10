import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/repositories/authentication_repository.dart';

/// Step three: sets the new password against the token step two returned.
///
/// Succeeding ends every session the account had, so the user signs in again
/// with what they just chose — there is no session handed back here.
class ResetPassword extends UseCase<void, ResetPasswordParams> {
  const ResetPassword(this._repository);

  final AuthenticationRepository _repository;

  @override
  ResultVoid call(ResetPasswordParams params) => _repository.resetPassword(
    resetToken: params.resetToken,
    newPassword: params.newPassword,
  );
}

class ResetPasswordParams extends Equatable {
  const ResetPasswordParams({
    required this.resetToken,
    required this.newPassword,
  });

  /// From `verify-otp`. One use, ten minutes.
  final String resetToken;

  /// 8–72 characters. The upper bound is bcrypt's, and the same one sign-up
  /// enforces — a longer password would be accepted here and then rejected at
  /// login, which locks the account for good.
  final String newPassword;

  @override
  List<Object?> get props => [resetToken, newPassword];
}
