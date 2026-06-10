import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/programs/domain/entities/program.dart';
import 'package:flutter_piggypal_app/features/programs/domain/repositories/programs_repository.dart';

/// Streams all programs items, re-emitting on any change.
class WatchProgramsList extends StreamUseCase<List<Program>, NoParams> {
  const WatchProgramsList(this._repository);

  final ProgramsRepository _repository;

  @override
  ResultStream<List<Program>> call(NoParams params) => _repository.watchAll();
}
