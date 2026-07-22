import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/languages/domain/entities/languages.dart';
import 'package:flutter_piggypal_app/features/languages/domain/repositories/languages_repository.dart';

class SaveLanguages extends UseCase<Languages, SaveLanguagesParams> {
  const SaveLanguages(this._repository);

  final LanguagesRepository _repository;

  @override
  ResultFuture<Languages> call(SaveLanguagesParams params) =>
      _repository.save(params.item);
}

class SaveLanguagesParams extends Equatable {
  const SaveLanguagesParams(this.item);

  final Languages item;

  @override
  List<Object?> get props => [item];
}
