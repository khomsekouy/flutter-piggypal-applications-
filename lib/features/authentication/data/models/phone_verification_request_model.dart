import 'package:flutter_piggypal_app/features/authentication/domain/entities/phone_verification_request.dart';

/// Data-layer [PhoneVerificationRequest]: reads
/// `POST /auth/verify-phone/request`'s body.
///
/// The body is `{ message, phoneVerified, devCode? }` — `phoneVerified` is
/// true only in the "nothing to do" case, where the server deliberately did
/// not spend a message re-proving a number it has already proved.
class PhoneVerificationRequestModel extends PhoneVerificationRequest {
  const PhoneVerificationRequestModel({
    required super.alreadyVerified,
    super.devCode,
  });

  factory PhoneVerificationRequestModel.fromJson(Map<String, dynamic> json) {
    final code = json['devCode'];
    return PhoneVerificationRequestModel(
      alreadyVerified: json['phoneVerified'] == true,
      devCode: code is String && code.isNotEmpty ? code : null,
    );
  }
}
