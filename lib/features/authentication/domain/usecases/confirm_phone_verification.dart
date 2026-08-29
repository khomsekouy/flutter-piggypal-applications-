import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/repositories/authentication_repository.dart';

/// Submits the six digits the user typed.
class ConfirmPhoneVerification
    extends UseCase<void, ConfirmPhoneVerificationParams> {
  const ConfirmPhoneVerification(this._repository);

  final AuthenticationRepository _repository;

  @override
  ResultVoid call(ConfirmPhoneVerificationParams params) =>
      _repository.confirmPhoneVerification(code: params.code);
}

class ConfirmPhoneVerificationParams extends Equatable {
  const ConfirmPhoneVerificationParams({required this.code});

  /// Exactly six digits — the server rejects anything else outright.
  final String code;

  @override
  List<Object?> get props => [code];
}
