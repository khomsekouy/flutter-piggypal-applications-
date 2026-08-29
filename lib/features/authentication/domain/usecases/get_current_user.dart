import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/entities/auth_user.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/repositories/authentication_repository.dart';

/// Reads the signed-in account from `GET /users/me`.
///
/// Also the app's session check: a 401 here means the stored token is gone,
/// expired or revoked, which the repository reports as an `AuthFailure`.
class GetCurrentUser extends UseCase<AuthUser, NoParams> {
  const GetCurrentUser(this._repository);

  final AuthenticationRepository _repository;

  @override
  ResultFuture<AuthUser> call(NoParams params) => _repository.getCurrentUser();
}
