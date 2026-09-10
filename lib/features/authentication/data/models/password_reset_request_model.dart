import 'package:flutter_piggypal_app/features/authentication/domain/entities/password_reset_request.dart';

/// Data-layer [PasswordResetRequest]: reads
/// `POST /auth/forgot-password`'s body.
///
/// The body is `{ message, devCode? }`. `message` is dropped on purpose — it
/// is the same "if the number is registered, a verification code was sent"
/// either way, so there is nothing in it for the app to act on, and showing
/// it verbatim would only repeat what the next screen already says.
class PasswordResetRequestModel extends PasswordResetRequest {
  const PasswordResetRequestModel({super.devCode});

  factory PasswordResetRequestModel.fromJson(Map<String, dynamic> json) {
    final code = json['devCode'];
    return PasswordResetRequestModel(
      devCode: code is String && code.isNotEmpty ? code : null,
    );
  }
}
