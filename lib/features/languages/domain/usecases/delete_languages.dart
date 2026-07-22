import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/languages/domain/repositories/languages_repository.dart';

class DeleteLanguages extends UseCase<void, DeleteLanguagesParams> {
  const DeleteLanguages(this._repository);

  final LanguagesRepository _repository;

  @override
  ResultVoid call(DeleteLanguagesParams params) =>
      _repository.delete(params.id);
}

class DeleteLanguagesParams extends Equatable {
  const DeleteLanguagesParams(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
