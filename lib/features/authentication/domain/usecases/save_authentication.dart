import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/entities/authentication.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/repositories/authentication_repository.dart';

class SaveAuthentication
    extends UseCase<Authentication, SaveAuthenticationParams> {
  const SaveAuthentication(this._repository);

  final AuthenticationRepository _repository;

  @override
  ResultFuture<Authentication> call(SaveAuthenticationParams params) =>
      _repository.save(params.item);
}

class SaveAuthenticationParams extends Equatable {
  const SaveAuthenticationParams(this.item);

  final Authentication item;

  @override
  List<Object?> get props => [item];
}
