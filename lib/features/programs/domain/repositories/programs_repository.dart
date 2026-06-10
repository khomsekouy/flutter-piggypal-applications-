import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/programs/domain/entities/program.dart';

/// Domain contract for the programs feature.
///
/// The data layer provides the implementation.
abstract interface class ProgramsRepository {
  ResultFuture<List<Program>> getAll();

  ResultStream<List<Program>> watchAll();

  ResultFuture<Program> save(Program item);

  ResultVoid delete(String id);
}
