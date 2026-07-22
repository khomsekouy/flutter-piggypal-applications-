import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/languages/domain/entities/languages.dart';

/// Domain contract for the languages feature.
///
/// The data layer provides the implementation.
abstract interface class LanguagesRepository {
  ResultFuture<List<Languages>> getAll();

  ResultStream<List<Languages>> watchAll();

  ResultFuture<Languages> save(Languages item);

  ResultVoid delete(String id);
}
