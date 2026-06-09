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
