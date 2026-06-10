import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/more/domain/entities/more.dart';

/// Domain contract for the more feature.
///
/// The data layer provides the implementation.
abstract interface class MoreRepository {
  ResultFuture<List<More>> getAll();

  ResultStream<List<More>> watchAll();

  ResultFuture<More> save(More item);

  ResultVoid delete(String id);
}
