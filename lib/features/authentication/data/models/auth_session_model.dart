import 'package:flutter_piggypal_app/features/authentication/data/models/auth_user_model.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/entities/auth_session.dart';

/// Data-layer [AuthSession] — the body of `POST /auth/login` and
/// `POST /auth/register`:
///
/// ```json
/// {
///   "message": "Signed in successfully",
///   "accessToken": "eyJ…",
///   "refreshToken": "…",
///   "user": { "id": "…", "phone": "+85597573235", … }
/// }
/// ```
class AuthSessionModel extends AuthSession {
  const AuthSessionModel({
    required super.accessToken,
    required super.refreshToken,
    required AuthUserModel super.user,
    super.message,
  });

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) =>
      AuthSessionModel(
        accessToken: '${json['accessToken']}',
        refreshToken: '${json['refreshToken']}',
        user: AuthUserModel.fromJson(
          Map<String, dynamic>.from(json['user'] as Map),
        ),
        message: json['message'] is String ? json['message'] as String : null,
      );
}
