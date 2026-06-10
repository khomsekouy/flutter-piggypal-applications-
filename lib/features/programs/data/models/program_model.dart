import 'package:drift/drift.dart';
import 'package:flutter_piggypal_app/core/database/app_database.dart';
import 'package:flutter_piggypal_app/features/programs/domain/entities/program.dart';

/// Data-layer representation of a [Program].
///
/// Extends the domain entity and adds the mapping to/from Drift rows. The
/// domain layer never sees this class — repositories return entities.
class ProgramModel extends Program {
  const ProgramModel({
    required super.id,
    required super.name,
    required super.code,
    required super.category,
    required super.status,
    required super.hue,
    required super.start,
    required super.end,
    required super.weeks,
    required super.location,
    required super.trainer,
    required super.capacity,
    required super.enrolled,
    required super.fee,
    required super.budget,
    required super.income,
    required super.spent,
    super.sortOrder,
  });

  /// Builds a model from a generated Drift row.
  factory ProgramModel.fromRow(ProgramRow row) {
    return ProgramModel(
      id: row.id,
      name: row.name,
      code: row.code,
      category: row.category,
      status: _statusFromDb(row.status),
      hue: row.hue,
      start: row.startLabel,
      end: row.endLabel,
      weeks: row.weeks,
      location: row.location,
      trainer: row.trainer,
      capacity: row.capacity,
      enrolled: row.enrolled,
      fee: row.fee,
      budget: row.budget,
      income: row.income,
      spent: row.spent,
      sortOrder: row.sortOrder,
    );
  }

  /// Widens any [Program] into a model so it can be persisted.
  factory ProgramModel.fromEntity(Program p) {
    return ProgramModel(
      id: p.id,
      name: p.name,
      code: p.code,
      category: p.category,
      status: p.status,
      hue: p.hue,
      start: p.start,
      end: p.end,
      weeks: p.weeks,
      location: p.location,
      trainer: p.trainer,
      capacity: p.capacity,
      enrolled: p.enrolled,
      fee: p.fee,
      budget: p.budget,
      income: p.income,
      spent: p.spent,
      sortOrder: p.sortOrder,
    );
  }

  /// Converts to a Drift companion for inserts/updates.
  ProgramsCompanion toCompanion() {
    return ProgramsCompanion(
      id: Value(id),
      name: Value(name),
      code: Value(code),
      category: Value(category),
      status: Value(status.name),
      hue: Value(hue),
      startLabel: Value(start),
      endLabel: Value(end),
      weeks: Value(weeks),
      location: Value(location),
      trainer: Value(trainer),
      capacity: Value(capacity),
      enrolled: Value(enrolled),
      fee: Value(fee),
      budget: Value(budget),
      income: Value(income),
      spent: Value(spent),
      sortOrder: Value(sortOrder),
    );
  }

  static ProgramStatus _statusFromDb(String s) => ProgramStatus.values
      .firstWhere((e) => e.name == s, orElse: () => ProgramStatus.active);
}
