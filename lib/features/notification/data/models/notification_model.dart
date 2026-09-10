import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_piggypal_app/core/database/app_database.dart';
import 'package:flutter_piggypal_app/features/notification/domain/entities/notification.dart';

/// Data-layer representation of an [AppNotification].
///
/// Extends the domain entity and adds the mapping to/from Drift rows. The
/// domain layer never sees this class — repositories return entities.
class NotificationModel extends AppNotification {
  const NotificationModel({
    required super.id,
    required super.kind,
    required super.title,
    required super.body,
    required super.receivedAt,
    super.read,
    super.target,
    super.targetParams,
  });

  /// Builds a model from a generated Drift row.
  factory NotificationModel.fromRow(NotificationRow row) {
    return NotificationModel(
      id: row.id,
      kind: _kindFromDb(row.kind),
      title: row.title,
      body: row.body,
      receivedAt: row.receivedAt,
      read: row.isRead,
      target: row.target,
      targetParams: _paramsFromDb(row.targetParams),
    );
  }

  /// Widens any [AppNotification] into a model so it can be persisted.
  factory NotificationModel.fromEntity(AppNotification n) {
    return NotificationModel(
      id: n.id,
      kind: n.kind,
      title: n.title,
      body: n.body,
      receivedAt: n.receivedAt,
      read: n.read,
      target: n.target,
      targetParams: n.targetParams,
    );
  }

  /// Converts to a Drift companion for inserts/updates.
  NotificationsCompanion toCompanion() {
    return NotificationsCompanion(
      id: Value(id),
      kind: Value(kind.name),
      title: Value(title),
      body: Value(body),
      receivedAt: Value(receivedAt),
      isRead: Value(read),
      target: Value(target),
      targetParams: Value(jsonEncode(targetParams)),
    );
  }

  static NotificationKind _kindFromDb(String s) => NotificationKind.values
      .firstWhere((e) => e.name == s, orElse: () => NotificationKind.system);

  /// Params are written by [toCompanion] and never by hand, but a row from an
  /// older build could still hold something unparseable — an unopenable
  /// target beats a crash on the list.
  static Map<String, Object?> _paramsFromDb(String s) {
    try {
      final decoded = jsonDecode(s);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } on FormatException {
      return const {};
    }
  }
}
