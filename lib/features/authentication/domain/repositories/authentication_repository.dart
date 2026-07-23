import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/entities/authentication.dart';

/// Domain contract for the authentication feature.
///
/// The data layer provides the implementation.
abstract interface class AuthenticationRepository {
  ResultFuture<List<Authentication>> getAll();

  ResultStream<List<Authentication>> watchAll();

  ResultFuture<Authentication> save(Authentication item);

  ResultVoid delete(String id);
}
