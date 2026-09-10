import 'package:drift/drift.dart';

/// Drift table for the notification centre.
///
/// The generated data class is `NotificationRow` (via [DataClassName]) so it
/// collides neither with the domain entity `AppNotification` nor with
/// Flutter's own `Notification`. [kind] is stored as the enum's name
/// (`payment` / `budget` / ...), [target] is the in-shell screen id a tap
/// opens (null for messages with nothing to open) and [targetParams] is that
/// screen's arguments as a JSON object — a map is not a column type, and
/// these are only ever read back whole.
@DataClassName('NotificationRow')
class Notifications extends Table {
  TextColumn get id => text()();
  TextColumn get kind => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get body => text()();
  DateTimeColumn get receivedAt => dateTime()();

  /// Named `isRead` because `read` reads as a verb on a database row.
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();

  TextColumn get target => text().nullable()();
  TextColumn get targetParams => text().withDefault(const Constant('{}'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
