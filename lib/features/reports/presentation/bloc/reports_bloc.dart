import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/features/reports/domain/entities/reports.dart';
import 'package:flutter_piggypal_app/features/reports/domain/usecases/delete_reports.dart';
import 'package:flutter_piggypal_app/features/reports/domain/usecases/watch_reports_list.dart';

part 'reports_event.dart';
part 'reports_state.dart';

/// Drives the reports use cases for the UI.
///
/// The list stays fresh via a live Drift stream, so writes never need a manual
/// refresh.
class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  ReportsBloc({
    required WatchReportsList watchReportsList,
    required DeleteReports deleteReports,
  }) : _watchReportsList = watchReportsList,
       _deleteReports = deleteReports,
       super(const ReportsState()) {
    on<ReportsSubscriptionRequested>(_onSubscriptionRequested);
    on<ReportsDeleted>(_onDeleted);
  }

  final WatchReportsList _watchReportsList;
  final DeleteReports _deleteReports;

  Future<void> _onSubscriptionRequested(
    ReportsSubscriptionRequested event,
    Emitter<ReportsState> emit,
  ) async {
    emit(state.copyWith(status: ReportsStatus.loading));
    await emit.forEach<List<Reports>>(
      _watchReportsList(const NoParams()),
      onData: (items) => state.copyWith(
        status: ReportsStatus.success,
        items: items,
      ),
      onError: (_, _) => state.copyWith(
        status: ReportsStatus.failure,
        errorMessage: 'Could not load data.',
      ),
    );
  }

  Future<void> _onDeleted(
    ReportsDeleted event,
    Emitter<ReportsState> emit,
  ) async {
    final result = await _deleteReports(DeleteReportsParams(event.id));
    result.match(
      (failure) => emit(
        state.copyWith(
          status: ReportsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) {},
    );
  }
}
