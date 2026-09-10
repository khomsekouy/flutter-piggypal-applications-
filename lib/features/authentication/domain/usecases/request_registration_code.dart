import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/entities/registration_code_request.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/repositories/authentication_repository.dart';

/// Sign-up step one: texts a code to a number that has no account yet.
///
/// Takes the number, unlike `RequestPhoneVerification`, and has to: there is
/// no session yet for the server to read one off.
class RequestRegistrationCode
    extends UseCase<RegistrationCodeRequest, RequestRegistrationCodeParams> {
  const RequestRegistrationCode(this._repository);

  final AuthenticationRepository _repository;

  @override
  ResultFuture<RegistrationCodeRequest> call(
    RequestRegistrationCodeParams params,
  ) => _repository.requestRegistrationCode(
    countryCode: params.countryCode,
    phone: params.phone,
  );
}

class RequestRegistrationCodeParams extends Equatable {
  const RequestRegistrationCodeParams({
    required this.countryCode,
    required this.phone,
  });

  final String countryCode;

  /// National number only — no dialling code, no leading zero.
  final String phone;

  @override
  List<Object?> get props => [countryCode, phone];
}
