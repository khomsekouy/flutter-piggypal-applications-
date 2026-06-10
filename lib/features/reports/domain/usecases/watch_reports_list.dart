import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/reports/domain/entities/reports.dart';
import 'package:flutter_piggypal_app/features/reports/domain/repositories/reports_repository.dart';

/// Streams all reports items, re-emitting on any change.
class WatchReportsList extends StreamUseCase<List<Reports>, NoParams> {
  const WatchReportsList(this._repository);

  final ReportsRepository _repository;

  @override
  ResultStream<List<Reports>> call(NoParams params) => _repository.watchAll();
}
