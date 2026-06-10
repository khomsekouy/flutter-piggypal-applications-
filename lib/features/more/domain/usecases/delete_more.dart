import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/more/domain/repositories/more_repository.dart';

class DeleteMore extends UseCase<void, DeleteMoreParams> {
  const DeleteMore(this._repository);

  final MoreRepository _repository;

  @override
  ResultVoid call(DeleteMoreParams params) => _repository.delete(params.id);
}

class DeleteMoreParams extends Equatable {
  const DeleteMoreParams(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
