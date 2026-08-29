/// Thrown by the data layer when a local-storage operation fails.
class DatabaseException implements Exception {
  const DatabaseException([this.message = 'A database error occurred.']);

  final String message;

  @override
  String toString() => 'DatabaseException: $message';
}

/// Thrown by the data layer when a requested record does not exist.
class NotFoundException implements Exception {
  const NotFoundException([this.message = 'Record not found.']);

  final String message;

  @override
  String toString() => 'NotFoundException: $message';
}

/// Thrown when the API answered, but with a non-2xx status.
///
/// [message] is already the human-readable text pulled off the response body
/// (NestJS returns `{ message, error, statusCode }`, where `message` is either
/// a string or a list of validation strings), so the UI can show it as-is.
class ServerException implements Exception {
  const ServerException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ServerException($statusCode): $message';
}

/// Thrown when the request never reached the API — no connection, DNS
/// failure, or a timeout.
class NetworkException implements Exception {
  const NetworkException([
    this.message = 'Could not reach the server. Check your connection.',
  ]);

  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

/// Thrown on a 401: no session, an expired access token, or a revoked one.
class UnauthorizedException implements Exception {
  const UnauthorizedException([this.message = 'Your session has expired.']);

  final String message;

  @override
  String toString() => 'UnauthorizedException: $message';
}

/// Thrown when a request was cancelled through its `CancelToken` — a screen
/// closing mid-flight, not a failure worth showing.
class RequestCancelledException implements Exception {
  const RequestCancelledException([this.message = 'Request cancelled.']);

  final String message;

  @override
  String toString() => 'RequestCancelledException: $message';
}

/// Thrown when reading or writing the device's secure storage fails.
class SecureStorageException implements Exception {
  const SecureStorageException([
    this.message = 'Could not access secure storage.',
  ]);

  final String message;

  @override
  String toString() => 'SecureStorageException: $message';
}

/// Thrown when a one-time code was rejected — wrong digits, expired, or too
/// many guesses already spent.
///
/// Separate from [UnauthorizedException] even though the API answers both
/// with a 401: this one says nothing about the session, and treating it as an
/// auth failure would sign the user out for a typo.
class InvalidVerificationCodeException implements Exception {
  const InvalidVerificationCodeException([
    this.message = 'That code is invalid or has expired.',
  ]);

  final String message;

  @override
  String toString() => 'InvalidVerificationCodeException: $message';
}
