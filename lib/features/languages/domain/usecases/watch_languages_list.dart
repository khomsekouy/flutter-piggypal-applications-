import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/languages/domain/entities/languages.dart';
import 'package:flutter_piggypal_app/features/languages/domain/repositories/languages_repository.dart';

/// Streams all languages items, re-emitting on any change.
class WatchLanguagesList extends StreamUseCase<List<Languages>, NoParams> {
  const WatchLanguagesList(this._repository);

  final LanguagesRepository _repository;

  @override
  ResultStream<List<Languages>> call(NoParams params) => _repository.watchAll();
}
