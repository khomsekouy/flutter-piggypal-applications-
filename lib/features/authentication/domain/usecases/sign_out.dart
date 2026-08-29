import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/repositories/authentication_repository.dart';

class SignOut extends UseCase<void, NoParams> {
  const SignOut(this._repository);

  final AuthenticationRepository _repository;

  @override
  ResultVoid call(NoParams params) => _repository.signOut();
}
