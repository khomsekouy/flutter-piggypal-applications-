import 'package:flutter_piggypal_app/features/reports/domain/entities/reports.dart';

/// Data-layer representation of [Reports].
///
/// Once you add the Drift table, give this a `fromRow(...)` factory and a
/// `toCompanion()` method (see features/transactions for a worked example).
class ReportsModel extends Reports {
  const ReportsModel({required super.id, required super.name});

  factory ReportsModel.fromEntity(Reports entity) =>
      ReportsModel(id: entity.id, name: entity.name);
}
