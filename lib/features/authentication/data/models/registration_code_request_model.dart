import 'package:flutter_piggypal_app/features/authentication/domain/entities/registration_code_request.dart';

/// Data-layer [RegistrationCodeRequest]: reads
/// `POST /auth/register/request-otp`'s body, which is
/// `{ expiresIn, devCode? }`.
///
/// `expiresIn` is whole seconds. A body without it is not treated as a
/// failure — nothing in the flow depends on the number, and the code it
/// announces was still issued.
class RegistrationCodeRequestModel extends RegistrationCodeRequest {
  const RegistrationCodeRequestModel({super.expiresIn, super.devCode});

  factory RegistrationCodeRequestModel.fromJson(Map<String, dynamic> json) {
    final expiresIn = json['expiresIn'];
    final code = json['devCode'];
    return RegistrationCodeRequestModel(
      expiresIn: expiresIn is num && expiresIn > 0
          ? Duration(seconds: expiresIn.toInt())
          : null,
      devCode: code is String && code.isNotEmpty ? code : null,
    );
  }
}
