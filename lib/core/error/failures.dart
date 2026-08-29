import 'package:equatable/equatable.dart';

/// Base class for all failures returned by the domain layer.
///
/// Failures are the *expected*, recoverable problems we surface to the UI,
/// as opposed to [Exception]s which are thrown by the data layer.
abstract class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// A problem occurred while talking to the local database.
class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Something went wrong with storage.']);
}

/// The requested record could not be found.
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'The item could not be found.']);
}

/// User input did not pass validation.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// The API answered with an error status.
class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'The server could not complete that request.',
    this.statusCode,
  ]);

  /// HTTP status behind the failure, when there was one.
  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

/// The request never reached the API.
class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Could not reach the server. Check your connection.',
  ]);
}

/// The caller has no valid session — sign in again.
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Your session has expired.']);
}

/// The request was cancelled by the caller; usually nothing to show.
class CancelledFailure extends Failure {
  const CancelledFailure([super.message = 'Request cancelled.']);
}

/// A one-time code was rejected. Not an [AuthFailure]: the session is fine,
/// the six digits were not.
class VerificationFailure extends Failure {
  const VerificationFailure([
    super.message = 'That code is invalid or has expired.',
  ]);
}
