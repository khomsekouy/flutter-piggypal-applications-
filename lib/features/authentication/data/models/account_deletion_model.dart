import 'package:flutter_piggypal_app/features/authentication/domain/entities/account_deletion.dart';

/// Data-layer [AccountDeletion] — the body of `POST /auth/delete-account`:
///
/// ```json
/// {
///   "message": "Account scheduled for deletion",
///   "purgeAt": "2026-10-02T08:00:00.000Z"
/// }
/// ```
class AccountDeletionModel extends AccountDeletion {
  const AccountDeletionModel({super.purgeAt, super.message});

  factory AccountDeletionModel.fromJson(Map<String, dynamic> json) {
    final purgeAt = json['purgeAt'];
    return AccountDeletionModel(
      // Parsed leniently and to local time: a missing or malformed date leaves
      // the window unnamed rather than failing a deletion that has already
      // happened server-side.
      purgeAt: purgeAt is String ? DateTime.tryParse(purgeAt)?.toLocal() : null,
      message: json['message'] is String ? json['message'] as String : null,
    );
  }
}
