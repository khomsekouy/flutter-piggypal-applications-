import 'package:flutter_piggypal_app/features/notification/data/datasources/notification_local_data_source.dart';
import 'package:flutter_piggypal_app/features/notification/data/models/notification_model.dart';
import 'package:flutter_piggypal_app/features/notification/domain/entities/notification.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/tf_nav.dart';

/// The initial notification rows.
///
/// Seeded relative to "now" so the Today / Yesterday grouping and the
/// "2h ago" labels are believable on first launch. Ids and targets match the
/// design's mock dataset, so tapping a row lands on the screen it names.
List<AppNotification> buildNotificationSeed() {
  final now = DateTime.now();
  return [
    AppNotification(
      id: 'n1',
      kind: NotificationKind.payment,
      title: 'Payment received',
      body: r'Yuki Tanaka paid $600 toward Advanced Data Analytics.',
      receivedAt: now.subtract(const Duration(minutes: 25)),
      target: TFScreens.participant,
      targetParams: const {'id': 'u3'},
    ),
    AppNotification(
      id: 'n2',
      kind: NotificationKind.budget,
      title: 'Materials & Print at 92%',
      body: 'Little room left in this line before it goes over.',
      receivedAt: now.subtract(const Duration(hours: 3)),
      target: TFScreens.budgets,
    ),
    AppNotification(
      id: 'n3',
      kind: NotificationKind.receipt,
      title: 'Receipts need matching',
      body: 'Uploaded this week but not yet tied to a transaction.',
      receivedAt: now.subtract(const Duration(hours: 6)),
      target: TFScreens.receipts,
    ),
    AppNotification(
      id: 'n4',
      kind: NotificationKind.program,
      title: 'Data Analytics Bootcamp is nearly full',
      body: '24 of 28 seats taken. Closes Jul 04.',
      receivedAt: now.subtract(const Duration(days: 1, hours: 2)),
      read: true,
      target: TFScreens.program,
      targetParams: const {'id': 'p1'},
    ),
    AppNotification(
      id: 'n5',
      kind: NotificationKind.payment,
      title: 'Fees still outstanding',
      body: 'Several participants have not settled their balance.',
      receivedAt: now.subtract(const Duration(days: 1, hours: 9)),
      read: true,
      target: TFScreens.participants,
    ),
    AppNotification(
      id: 'n6',
      kind: NotificationKind.system,
      title: 'Monthly report ready',
      body: 'Your profit and loss statement for last month is available.',
      receivedAt: now.subtract(const Duration(days: 4)),
      read: true,
      target: TFScreens.pnl,
    ),
    AppNotification(
      id: 'n7',
      kind: NotificationKind.system,
      title: 'Signed in on a new device',
      body: 'Android · Phnom Penh. Not you? Change your password.',
      receivedAt: now.subtract(const Duration(days: 6)),
      read: true,
      target: TFScreens.changePassword,
    ),
  ];
}

/// Inserts the seed rows once, on an empty table. Safe to call on every
/// launch — and because it only fires when empty, clearing the centre stays
/// cleared instead of refilling on the next start.
Future<void> seedNotifications(NotificationLocalDataSource local) async {
  if ((await local.getAll()).isNotEmpty) return;
  for (final n in buildNotificationSeed()) {
    await local.save(NotificationModel.fromEntity(n));
  }
}
