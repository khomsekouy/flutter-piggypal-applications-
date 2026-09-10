import 'package:equatable/equatable.dart';

/// What a notification is about. Decides its icon, tint and where tapping it
/// takes the user.
enum NotificationKind {
  /// A participant paid, or still owes, a program fee.
  payment,

  /// A budget line crossed a threshold.
  budget,

  /// A receipt needs matching or review.
  receipt,

  /// A program started, filled up or wrapped.
  program,

  /// Account and app-level messages.
  system,
}

/// One item in the notification centre.
///
/// Pure Dart — no Flutter, no Drift. Named `AppNotification` rather than
/// `Notification` because `package:flutter/material.dart` exports a class by
/// that name, and the screens import both.
///
/// [target] is the in-shell screen a tap opens (see `TFScreens`); leave it
/// null for messages with nothing to open.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.read = false,
    this.target,
    this.targetParams = const {},
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final DateTime receivedAt;
  final bool read;
  final String? target;
  final Map<String, Object?> targetParams;

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    kind: kind,
    title: title,
    body: body,
    receivedAt: receivedAt,
    read: read ?? this.read,
    target: target,
    targetParams: targetParams,
  );

  @override
  List<Object?> get props => [
    id,
    kind,
    title,
    body,
    receivedAt,
    read,
    target,
    targetParams,
  ];
}
