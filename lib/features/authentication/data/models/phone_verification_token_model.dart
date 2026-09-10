import 'package:flutter_piggypal_app/core/error/exceptions.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/entities/phone_verification_token.dart';

/// Data-layer [PhoneVerificationToken]: reads
/// `POST /auth/register/verify-otp`'s body, which is `{ verificationToken }`
/// and nothing else.
class PhoneVerificationTokenModel extends PhoneVerificationToken {
  const PhoneVerificationTokenModel({required super.token});

  factory PhoneVerificationTokenModel.fromJson(Map<String, dynamic> json) {
    final token = json['verificationToken'];
    // A 200 without the token means the app is talking to something that is
    // not this API. Failing here beats carrying an empty string to the
    // password pane and registering an unverified account with it — which is
    // exactly what the server does with a `verificationToken` it never sees.
    if (token is! String || token.isEmpty) {
      throw const ServerException('The server returned no verification token.');
    }
    return PhoneVerificationTokenModel(token: token);
  }
}
