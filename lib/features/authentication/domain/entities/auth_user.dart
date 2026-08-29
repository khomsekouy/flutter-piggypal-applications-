import 'package:equatable/equatable.dart';

/// The signed-in account, as `GET /users/me` describes it.
///
/// Everything but [id] and [phone] is optional because the API says so: an
/// account can be created with a number and a password alone.
class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.phone,
    this.email,
    this.name,
    this.avatarUrl,
    this.currency,
    this.status,
    this.phoneVerified = false,
    this.emailVerified = false,
    this.createdAt,
  });

  /// Server-side UUID.
  final String id;

  /// E.164, as stored — `countryCode` and the national number joined
  /// (`+85597573235`).
  final String phone;

  final String? email;
  final String? name;

  /// Absolute URL of the uploaded avatar, served from the API's `/uploads`.
  final String? avatarUrl;

  /// Preferred currency code, e.g. `USD`.
  final String? currency;

  /// Account status — `active`, `blocked`, `pending_deletion`.
  final String? status;

  final bool phoneVerified;
  final bool emailVerified;

  /// When the account was created; drives the "Joined …" line.
  final DateTime? createdAt;

  /// Name if there is one, otherwise the number — never an empty string, so
  /// the UI has something to render.
  String get displayName {
    final trimmed = name?.trim();
    return (trimmed == null || trimmed.isEmpty) ? phone : trimmed;
  }

  @override
  List<Object?> get props => [
    id,
    phone,
    email,
    name,
    avatarUrl,
    currency,
    status,
    phoneVerified,
    emailVerified,
    createdAt,
  ];
}
