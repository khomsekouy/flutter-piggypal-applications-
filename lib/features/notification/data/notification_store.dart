import 'package:flutter/foundation.dart';
import 'package:flutter_piggypal_app/features/training_finance/presentation/tf_nav.dart';

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
/// [target] is the in-shell screen a tap opens (see [TFScreens]); leave it
/// null for messages with nothing to open.
class AppNotification {
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
}

/// Which day-group a notification falls into on the list.
enum NotificationSection { today, yesterday, earlier }

/// In-memory store of the notification centre, shared by the bell badge and
/// the notification screen.
///
/// Front-end only (mirrors `ProfileStore` / `BudgetStore`): seeded with mock
/// items and notifying on read/delete. Not persisted — feed it from a real
/// push/repository layer to survive restarts.
class NotificationStore {
  NotificationStore._();
  static final NotificationStore instance = NotificationStore._();

  /// Newest first — the order the screen renders in.
  final ValueNotifier<List<AppNotification>> items = ValueNotifier(_seed());

  /// Drives the badge on the bell. Separate from [items] so the badge only
  /// rebuilds when the count actually moves.
  final ValueNotifier<int> unreadCount = ValueNotifier(
    _seed().where((n) => !n.read).length,
  );

  void _publish(List<AppNotification> next) {
    items.value = next;
    unreadCount.value = next.where((n) => !n.read).length;
  }

  /// Marks one item read. No-op if it is already read or gone.
  void markRead(String id) => _publish([
    for (final n in items.value)
      if (n.id == id) n.copyWith(read: true) else n,
  ]);

  void markAllRead() =>
      _publish([for (final n in items.value) n.copyWith(read: true)]);

  /// Removes an item, returning where it sat so [restore] can undo it.
  int remove(String id) {
    final index = items.value.indexWhere((n) => n.id == id);
    if (index < 0) return -1;
    _publish([...items.value]..removeAt(index));
    return index;
  }

  /// Puts a removed item back at [index] (used by the undo action).
  void restore(AppNotification item, int index) {
    final next = [...items.value];
    next.insert(index.clamp(0, next.length), item);
    _publish(next);
  }

  void clearAll() => _publish([]);

  /// Puts the seeded items back. The store is a singleton, so tests that mark
  /// items read would otherwise leak that state into the next test.
  @visibleForTesting
  void resetForTesting() => _publish(_seed());

  /// Seeded relative to "now" so the Today / Yesterday grouping and the
  /// "2h ago" labels stay believable whenever the app is opened.
  static List<AppNotification> _seed() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'n1',
        kind: NotificationKind.payment,
        title: 'Payment received',
        body: r'Yuki Tanaka paid $600 toward Advanced Data Analytics.',
        receivedAt: now.subtract(const Duration(minutes: 25)),
        target: TFScreens.participant,
        targetParams: {'id': 'u3'},
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
        targetParams: {'id': 'p1'},
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
}

/// Which day-group [at] belongs to, relative to [now].
NotificationSection sectionOf(DateTime at, DateTime now) {
  final startOfToday = DateTime(now.year, now.month, now.day);
  if (!at.isBefore(startOfToday)) return NotificationSection.today;
  if (!at.isBefore(startOfToday.subtract(const Duration(days: 1)))) {
    return NotificationSection.yesterday;
  }
  return NotificationSection.earlier;
}

/// Short relative age — "now", "25m", "3h", "4d".
String timeAgo(DateTime at, DateTime now) {
  final diff = now.difference(at);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${(diff.inDays / 7).floor()}w';
}
