import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/programs/domain/repositories/programs_repository.dart';

class DeletePrograms extends UseCase<void, DeleteProgramsParams> {
  const DeletePrograms(this._repository);

  final ProgramsRepository _repository;

  @override
  ResultVoid call(DeleteProgramsParams params) => _repository.delete(params.id);
}

class DeleteProgramsParams extends Equatable {
  const DeleteProgramsParams(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
