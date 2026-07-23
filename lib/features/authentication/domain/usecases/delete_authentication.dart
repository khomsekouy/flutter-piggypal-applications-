import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/repositories/authentication_repository.dart';

class DeleteAuthentication extends UseCase<void, DeleteAuthenticationParams> {
  const DeleteAuthentication(this._repository);

  final AuthenticationRepository _repository;

  @override
  ResultVoid call(DeleteAuthenticationParams params) =>
      _repository.delete(params.id);
}

class DeleteAuthenticationParams extends Equatable {
  const DeleteAuthenticationParams(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
