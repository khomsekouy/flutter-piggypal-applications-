import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/features/languages/domain/entities/languages.dart';
import 'package:flutter_piggypal_app/features/languages/domain/usecases/delete_languages.dart';
import 'package:flutter_piggypal_app/features/languages/domain/usecases/watch_languages_list.dart';

part 'languages_event.dart';
part 'languages_state.dart';

/// Drives the languages use cases for the UI.
///
/// The list stays fresh via a live Drift stream, so writes never need a manual
/// refresh.
class LanguagesBloc extends Bloc<LanguagesEvent, LanguagesState> {
  LanguagesBloc({
    required WatchLanguagesList watchLanguagesList,
    required DeleteLanguages deleteLanguages,
  }) : _watchLanguagesList = watchLanguagesList,
       _deleteLanguages = deleteLanguages,
       super(const LanguagesState()) {
    on<LanguagesSubscriptionRequested>(_onSubscriptionRequested);
    on<LanguagesDeleted>(_onDeleted);
  }

  final WatchLanguagesList _watchLanguagesList;
  final DeleteLanguages _deleteLanguages;

  Future<void> _onSubscriptionRequested(
    LanguagesSubscriptionRequested event,
    Emitter<LanguagesState> emit,
  ) async {
    emit(state.copyWith(status: LanguagesStatus.loading));
    await emit.forEach<List<Languages>>(
      _watchLanguagesList(const NoParams()),
      onData: (items) => state.copyWith(
        status: LanguagesStatus.success,
        items: items,
      ),
      onError: (_, _) => state.copyWith(
        status: LanguagesStatus.failure,
        errorMessage: 'Could not load data.',
      ),
    );
  }

  Future<void> _onDeleted(
    LanguagesDeleted event,
    Emitter<LanguagesState> emit,
  ) async {
    final result = await _deleteLanguages(DeleteLanguagesParams(event.id));
    result.match(
      (failure) => emit(
        state.copyWith(
          status: LanguagesStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) {},
    );
  }
}
