import 'package:drift/drift.dart';

/// Drift table for training programs.
///
/// The generated data class is named `ProgramRow` (via [DataClassName]) so it
/// does not collide with the domain entity `Program`. `status` is stored as a
/// text enum name (`active` / `upcoming` / `completed`); the date fields are
/// human labels (e.g. `May 12`) rather than real `DateTime`s, matching the
/// design's data shape.
@DataClassName('ProgramRow')
class Programs extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get code => text()();
  TextColumn get category => text()();
  TextColumn get status => text()();
  RealColumn get hue => real()();
  TextColumn get startLabel => text()();
  TextColumn get endLabel => text()();
  IntColumn get weeks => integer()();
  TextColumn get location => text()();
  TextColumn get trainer => text()();
  IntColumn get capacity => integer()();
  IntColumn get enrolled => integer()();
  RealColumn get fee => real()();
  RealColumn get budget => real()();
  RealColumn get income => real()();
  RealColumn get spent => real()();

  /// Display order on the list (mirrors the design's fixed ordering).
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
