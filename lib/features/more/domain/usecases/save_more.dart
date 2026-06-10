import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/more/domain/entities/more.dart';
import 'package:flutter_piggypal_app/features/more/domain/repositories/more_repository.dart';

class SaveMore extends UseCase<More, SaveMoreParams> {
  const SaveMore(this._repository);

  final MoreRepository _repository;

  @override
  ResultFuture<More> call(SaveMoreParams params) =>
      _repository.save(params.item);
}

class SaveMoreParams extends Equatable {
  const SaveMoreParams(this.item);

  final More item;

  @override
  List<Object?> get props => [item];
}
