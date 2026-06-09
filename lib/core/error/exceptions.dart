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
