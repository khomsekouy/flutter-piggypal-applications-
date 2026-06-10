import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/features/more/domain/entities/more.dart';
import 'package:flutter_piggypal_app/features/more/domain/usecases/delete_more.dart';
import 'package:flutter_piggypal_app/features/more/domain/usecases/watch_more_list.dart';

part 'more_event.dart';
part 'more_state.dart';

/// Drives the more use cases for the UI.
///
/// The list stays fresh via a live Drift stream, so writes never need a manual
/// refresh.
class MoreBloc extends Bloc<MoreEvent, MoreState> {
  MoreBloc({
    required WatchMoreList watchMoreList,
    required DeleteMore deleteMore,
  }) : _watchMoreList = watchMoreList,
       _deleteMore = deleteMore,
       super(const MoreState()) {
    on<MoreSubscriptionRequested>(_onSubscriptionRequested);
    on<MoreDeleted>(_onDeleted);
  }

  final WatchMoreList _watchMoreList;
  final DeleteMore _deleteMore;

  Future<void> _onSubscriptionRequested(
    MoreSubscriptionRequested event,
    Emitter<MoreState> emit,
  ) async {
    emit(state.copyWith(status: MoreStatus.loading));
    await emit.forEach<List<More>>(
      _watchMoreList(const NoParams()),
      onData: (items) => state.copyWith(
        status: MoreStatus.success,
        items: items,
      ),
      onError: (_, _) => state.copyWith(
        status: MoreStatus.failure,
        errorMessage: 'Could not load data.',
      ),
    );
  }

  Future<void> _onDeleted(
    MoreDeleted event,
    Emitter<MoreState> emit,
  ) async {
    final result = await _deleteMore(DeleteMoreParams(event.id));
    result.match(
      (failure) => emit(
        state.copyWith(
          status: MoreStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) {},
    );
  }
}
