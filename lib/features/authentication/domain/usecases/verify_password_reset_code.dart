import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/entities/password_reset_token.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/repositories/authentication_repository.dart';

/// Step two: submits the six digits and gets back the ticket that lets the
/// password actually be changed.
///
/// Unlike `ConfirmPhoneVerification` this carries the number, because the
/// caller has no session for the server to read one from.
class VerifyPasswordResetCode
    extends UseCase<PasswordResetToken, VerifyPasswordResetCodeParams> {
  const VerifyPasswordResetCode(this._repository);

  final AuthenticationRepository _repository;

  @override
  ResultFuture<PasswordResetToken> call(VerifyPasswordResetCodeParams params) =>
      _repository.verifyPasswordResetCode(
        countryCode: params.countryCode,
        phone: params.phone,
        code: params.code,
      );
}

class VerifyPasswordResetCodeParams extends Equatable {
  const VerifyPasswordResetCodeParams({
    required this.countryCode,
    required this.phone,
    required this.code,
  });

  final String countryCode;

  /// The **national** number the code was sent to.
  final String phone;

  /// Exactly six digits — the server rejects anything else outright.
  final String code;

  @override
  List<Object?> get props => [countryCode, phone, code];
}
