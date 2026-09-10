import 'package:flutter_piggypal_app/core/error/exceptions.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/entities/password_reset_token.dart';

/// Data-layer [PasswordResetToken]: reads `POST /auth/verify-otp`'s body,
/// which is `{ resetToken }` and nothing else.
class PasswordResetTokenModel extends PasswordResetToken {
  const PasswordResetTokenModel({required super.token});

  factory PasswordResetTokenModel.fromJson(Map<String, dynamic> json) {
    final token = json['resetToken'];
    // A 200 without the token means the app is talking to something that is
    // not this API. Failing here beats carrying an empty string to the next
    // screen and calling `reset-password` with it.
    if (token is! String || token.isEmpty) {
      throw const ServerException('The server returned no reset token.');
    }
    return PasswordResetTokenModel(token: token);
  }
}
