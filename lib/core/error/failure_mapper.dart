import 'package:flutter_piggypal_app/core/error/exceptions.dart';
import 'package:flutter_piggypal_app/core/error/failures.dart';

/// Maps a data-layer exception onto the `Failure` the UI understands.
///
/// One place, so every repository reports the same problem the same way — and
/// so a new exception type cannot quietly become "something went wrong" in
/// half the app and a crash in the other half.
Failure failureFromException(Object error) => switch (error) {
  InvalidVerificationCodeException(:final message) => VerificationFailure(
    message,
  ),
  UnauthorizedException(:final message) => AuthFailure(message),
  ServerException(:final message, :final statusCode) => ServerFailure(
    message,
    statusCode,
  ),
  NetworkException(:final message) => NetworkFailure(message),
  RequestCancelledException(:final message) => CancelledFailure(message),
  SecureStorageException(:final message) => DatabaseFailure(message),
  DatabaseException(:final message) => DatabaseFailure(message),
  NotFoundException(:final message) => NotFoundFailure(message),
  _ => const ServerFailure(),
};
