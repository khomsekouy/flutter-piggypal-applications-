import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/entities/phone_verification_request.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/repositories/authentication_repository.dart';

/// Asks the server to text a fresh verification code to the signed-in
/// account's number.
///
/// [NoParams] because there is nothing to pass: the number comes from the
/// session, by the API's design.
class RequestPhoneVerification
    extends UseCase<PhoneVerificationRequest, NoParams> {
  const RequestPhoneVerification(this._repository);

  final AuthenticationRepository _repository;

  @override
  ResultFuture<PhoneVerificationRequest> call(NoParams params) =>
      _repository.requestPhoneVerification();
}
