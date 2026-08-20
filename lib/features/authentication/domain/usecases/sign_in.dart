import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/entities/auth_session.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/repositories/authentication_repository.dart';

class SignIn extends UseCase<AuthSession, SignInParams> {
  const SignIn(this._repository);

  final AuthenticationRepository _repository;

  @override
  ResultFuture<AuthSession> call(SignInParams params) => _repository.signIn(
    countryCode: params.countryCode,
    phone: params.phone,
    password: params.password,
  );
}

class SignInParams extends Equatable {
  const SignInParams({
    required this.countryCode,
    required this.phone,
    required this.password,
  });

  final String countryCode;

  /// National number only — no dialling code, no leading zero.
  final String phone;
  final String password;

  @override
  List<Object?> get props => [countryCode, phone, password];
}
