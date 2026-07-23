import 'package:flutter_piggypal_app/features/authentication/domain/entities/authentication.dart';

/// Data-layer representation of [Authentication].
///
/// Once you add the Drift table, give this a `fromRow(...)` factory and a
/// `toCompanion()` method (see features/transactions for a worked example).
class AuthenticationModel extends Authentication {
  const AuthenticationModel({required super.id, required super.name});

  factory AuthenticationModel.fromEntity(Authentication entity) =>
      AuthenticationModel(id: entity.id, name: entity.name);
}
