import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/reports/domain/entities/reports.dart';

/// Domain contract for the reports feature.
///
/// The data layer provides the implementation.
abstract interface class ReportsRepository {
  ResultFuture<List<Reports>> getAll();

  ResultStream<List<Reports>> watchAll();

  ResultFuture<Reports> save(Reports item);

  ResultVoid delete(String id);
}
