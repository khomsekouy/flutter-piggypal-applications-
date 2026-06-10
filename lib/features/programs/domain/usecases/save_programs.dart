import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/programs/domain/entities/program.dart';
import 'package:flutter_piggypal_app/features/programs/domain/repositories/programs_repository.dart';

class SavePrograms extends UseCase<Program, SaveProgramsParams> {
  const SavePrograms(this._repository);

  final ProgramsRepository _repository;

  @override
  ResultFuture<Program> call(SaveProgramsParams params) =>
      _repository.save(params.item);
}

class SaveProgramsParams extends Equatable {
  const SaveProgramsParams(this.item);

  final Program item;

  @override
  List<Object?> get props => [item];
}
