import 'package:flutter_piggypal_app/features/more/domain/entities/more.dart';

/// Data-layer representation of [More].
///
/// Once you add the Drift table, give this a `fromRow(...)` factory and a
/// `toCompanion()` method (see features/transactions for a worked example).
class MoreModel extends More {
  const MoreModel({required super.id, required super.name});

  factory MoreModel.fromEntity(More entity) =>
      MoreModel(id: entity.id, name: entity.name);
}
