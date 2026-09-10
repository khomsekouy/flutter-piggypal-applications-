import 'package:equatable/equatable.dart';
import 'package:flutter_piggypal_app/core/usecases/usecase.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/entities/password_reset_request.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/repositories/authentication_repository.dart';

/// Step one of the password reset: ask for a code to be texted to a number.
///
/// Doubles as the resend — the server retires whatever code was live and
/// issues a new one either way, exactly as `verify-phone/request` does.
class RequestPasswordReset
    extends UseCase<PasswordResetRequest, RequestPasswordResetParams> {
  const RequestPasswordReset(this._repository);

  final AuthenticationRepository _repository;

  @override
  ResultFuture<PasswordResetRequest> call(RequestPasswordResetParams params) =>
      _repository.requestPasswordReset(
        countryCode: params.countryCode,
        phone: params.phone,
      );
}

class RequestPasswordResetParams extends Equatable {
  const RequestPasswordResetParams({
    required this.countryCode,
    required this.phone,
  });

  /// The dialling code (`+855`).
  final String countryCode;

  /// The **national** number only (`12345678`) — the server joins the two.
  final String phone;

  @override
  List<Object?> get props => [countryCode, phone];
}
