import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/entities/account_deletion.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/repositories/authentication_repository.dart';

class DeleteAccount extends UseCase<AccountDeletion, DeleteAccountParams> {
  const DeleteAccount(this._repository);

  final AuthenticationRepository _repository;

  @override
  ResultFuture<AccountDeletion> call(DeleteAccountParams params) =>
      _repository.deleteAccount(password: params.password);
}

class DeleteAccountParams extends Equatable {
  const DeleteAccountParams({required this.password});

  /// Re-typed at the confirmation screen. The session alone must not be enough
  /// to destroy an account.
  final String password;

  @override
  List<Object?> get props => [password];
}
