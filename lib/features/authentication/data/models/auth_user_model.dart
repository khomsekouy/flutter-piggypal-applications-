import 'package:flutter_piggypal_app/features/authentication/domain/entities/auth_user.dart';

/// Data-layer [AuthUser]: knows how to read the API's JSON.
///
/// Handles both shapes the API returns a user in — the fuller
/// `GET /users/me` body and the smaller `user` object nested in a sign-in or
/// sign-up response (id, phone, email, name, avatarUrl only) — by treating
/// every field but `id` and `phone` as optional.
class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.id,
    required super.phone,
    super.email,
    super.name,
    super.avatarUrl,
    super.currency,
    super.status,
    super.phoneVerified,
    super.emailVerified,
    super.createdAt,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) => AuthUserModel(
    id: '${json['id']}',
    phone: '${json['phone']}',
    email: _string(json['email']),
    name: _string(json['name']),
    avatarUrl: _string(json['avatarUrl']),
    currency: _string(json['currency']),
    status: _string(json['status']),
    phoneVerified: json['phoneVerified'] == true,
    emailVerified: json['emailVerified'] == true,
    createdAt: _dateTime(json['createdAt']),
  );

  /// Null rather than the string `"null"` — every one of these is nullable
  /// server-side, and `'${json['email']}'` on a null would render as text.
  static String? _string(Object? value) {
    if (value == null) return null;
    final text = '$value'.trim();
    return text.isEmpty ? null : text;
  }

  static DateTime? _dateTime(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
