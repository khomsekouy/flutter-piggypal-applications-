import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/entities/auth_session.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/repositories/authentication_repository.dart';

class SignUp extends UseCase<AuthSession, SignUpParams> {
  const SignUp(this._repository);

  final AuthenticationRepository _repository;

  @override
  ResultFuture<AuthSession> call(SignUpParams params) => _repository.signUp(
    countryCode: params.countryCode,
    phone: params.phone,
    password: params.password,
    email: params.email,
    name: params.name,
    avatar: params.avatar,
    avatarFileName: params.avatarFileName,
  );
}

class SignUpParams extends Equatable {
  const SignUpParams({
    required this.countryCode,
    required this.phone,
    required this.password,
    this.email,
    this.name,
    this.avatar,
    this.avatarFileName,
  });

  final String countryCode;

  /// National number only — no dialling code, no leading zero.
  final String phone;
  final String password;
  final String? email;
  final String? name;

  /// Profile photo bytes, uploaded with the account in the same request.
  final Uint8List? avatar;
  final String? avatarFileName;

  @override
  List<Object?> get props => [
    countryCode,
    phone,
    password,
    email,
    name,
    avatar,
    avatarFileName,
  ];
}
