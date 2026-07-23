import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/entities/authentication.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/repositories/authentication_repository.dart';

/// Streams all authentication items, re-emitting on any change.
class WatchAuthenticationList
    extends StreamUseCase<List<Authentication>, NoParams> {
  const WatchAuthenticationList(this._repository);

  final AuthenticationRepository _repository;

  @override
  ResultStream<List<Authentication>> call(NoParams params) =>
      _repository.watchAll();
}
