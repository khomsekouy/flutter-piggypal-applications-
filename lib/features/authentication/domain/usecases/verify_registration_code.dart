import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/entities/phone_verification_token.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/repositories/authentication_repository.dart';

/// Sign-up step two: trades the six digits for the proof that sign-up itself
/// spends.
class VerifyRegistrationCode
    extends UseCase<PhoneVerificationToken, VerifyRegistrationCodeParams> {
  const VerifyRegistrationCode(this._repository);

  final AuthenticationRepository _repository;

  @override
  ResultFuture<PhoneVerificationToken> call(
    VerifyRegistrationCodeParams params,
  ) => _repository.verifyRegistrationCode(
    countryCode: params.countryCode,
    phone: params.phone,
    code: params.code,
  );
}

class VerifyRegistrationCodeParams extends Equatable {
  const VerifyRegistrationCodeParams({
    required this.countryCode,
    required this.phone,
    required this.code,
  });

  final String countryCode;

  /// The same number step one was asked for: the code was issued against it,
  /// so it is what identifies the code to check against.
  final String phone;
  final String code;

  @override
  List<Object?> get props => [countryCode, phone, code];
}
