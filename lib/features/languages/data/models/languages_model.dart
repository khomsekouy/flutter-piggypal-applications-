import 'package:flutter_piggypal_app/features/languages/domain/entities/languages.dart';

/// Data-layer representation of [Languages].
///
/// Once you add the Drift table, give this a `fromRow(...)` factory and a
/// `toCompanion()` method (see features/transactions for a worked example).
class LanguagesModel extends Languages {
  const LanguagesModel({required super.id, required super.name});

  factory LanguagesModel.fromEntity(Languages entity) =>
      LanguagesModel(id: entity.id, name: entity.name);
}
