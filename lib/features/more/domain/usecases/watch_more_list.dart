import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/more/domain/entities/more.dart';
import 'package:flutter_piggypal_app/features/more/domain/repositories/more_repository.dart';

/// Streams all more items, re-emitting on any change.
class WatchMoreList extends StreamUseCase<List<More>, NoParams> {
  const WatchMoreList(this._repository);

  final MoreRepository _repository;

  @override
  ResultStream<List<More>> call(NoParams params) => _repository.watchAll();
}
