import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/features/programs/domain/entities/program.dart';
import 'package:flutter_piggypal_app/features/programs/domain/usecases/delete_programs.dart';
import 'package:flutter_piggypal_app/features/programs/domain/usecases/watch_programs_list.dart';

part 'programs_event.dart';
part 'programs_state.dart';

/// Drives the programs use cases for the UI.
///
/// The list stays fresh via a live Drift stream, so writes never need a manual
/// refresh.
class ProgramsBloc extends Bloc<ProgramsEvent, ProgramsState> {
  ProgramsBloc({
    required WatchProgramsList watchProgramsList,
    required DeletePrograms deletePrograms,
  }) : _watchProgramsList = watchProgramsList,
       _deletePrograms = deletePrograms,
       super(const ProgramsState()) {
    on<ProgramsSubscriptionRequested>(_onSubscriptionRequested);
    on<ProgramsDeleted>(_onDeleted);
  }

  final WatchProgramsList _watchProgramsList;
  final DeletePrograms _deletePrograms;

  Future<void> _onSubscriptionRequested(
    ProgramsSubscriptionRequested event,
    Emitter<ProgramsState> emit,
  ) async {
    emit(state.copyWith(status: ProgramsStatus.loading));
    await emit.forEach<List<Program>>(
      _watchProgramsList(const NoParams()),
      onData: (items) => state.copyWith(
        status: ProgramsStatus.success,
        items: items,
      ),
      onError: (_, _) => state.copyWith(
        status: ProgramsStatus.failure,
        errorMessage: 'Could not load data.',
      ),
    );
  }

  Future<void> _onDeleted(
    ProgramsDeleted event,
    Emitter<ProgramsState> emit,
  ) async {
    final result = await _deletePrograms(DeleteProgramsParams(event.id));
    result.match(
      (failure) => emit(
        state.copyWith(
          status: ProgramsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) {},
    );
  }
}
