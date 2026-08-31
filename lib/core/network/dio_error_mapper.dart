import 'package:dio/dio.dart';
import 'package:flutter_piggypal_app/core/error/exceptions.dart';

/// Turns a [DioException] into one of the app's own exceptions.
///
/// Data sources call this in a single `on DioException catch` so the rest of
/// the app never imports dio: the repository maps these onto `Failure`s and
/// the UI only ever sees a message.
Exception mapDioException(DioException error) {
  switch (error.type) {
    case DioExceptionType.cancel:
      return const RequestCancelledException();
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const NetworkException('The server took too long to respond.');
    case DioExceptionType.connectionError:
    case DioExceptionType.unknown:
      return const NetworkException();
    case DioExceptionType.badCertificate:
      return const NetworkException('The server certificate was rejected.');
    case DioExceptionType.badResponse:
      final response = error.response;
      final status = response?.statusCode;
      final message = messageFromBody(response?.data);
      if (status == 401 || status == 403) {
        return UnauthorizedException(
          message ?? 'Your session has expired. Please sign in again.',
        );
      }
      if (status == 429) {
        return ServerException(throttledMessage(response), statusCode: status);
      }
      return ServerException(
        message ?? 'The server could not complete that request.',
        statusCode: status,
      );
  }
}

/// Copy for a 429, written here because the API never writes its own.
///
/// The body's `message` is dropped on purpose: NestJS's throttler answers with
/// a fixed `ThrottlerException: Too Many Requests`, the class name of a
/// framework internal, and putting that in a snackbar is how the resend on
/// `verify-phone/request` used to read. It does send `Retry-After`, so when
/// the header is there the wait can be named instead of guessed at.
String throttledMessage(Response<dynamic>? response) {
  final seconds = _retryAfterSeconds(response);
  if (seconds == null || seconds <= 0) {
    return 'Too many attempts. Please wait a few minutes and try again.';
  }
  if (seconds < 60) {
    final unit = seconds == 1 ? 'second' : 'seconds';
    return 'Too many attempts. Try again in $seconds $unit.';
  }
  // Rounded up, so the number never tells the user to retry early.
  final minutes = (seconds / 60).ceil();
  final unit = minutes == 1 ? 'minute' : 'minutes';
  return 'Too many attempts. Try again in $minutes $unit.';
}

/// `Retry-After` as whole seconds, or null when it is absent or a date.
///
/// Read through `[]` rather than `Headers.value`, which throws when a header
/// arrives twice — nothing in a function that maps an error may itself throw.
/// The HTTP-date form is legal but not one this API sends; it parses as null
/// here, which lands on the generic wording.
int? _retryAfterSeconds(Response<dynamic>? response) {
  final values = response?.headers['retry-after'];
  if (values == null || values.isEmpty) return null;
  return int.tryParse(values.first.trim());
}

/// Pulls the human-readable text out of a NestJS error body.
///
/// The shape is `{ message, error, statusCode }`, where `message` is a string
/// for thrown exceptions (`'Phone is already registered'`) but a *list* of
/// strings when the global `ValidationPipe` rejects the body — so both have to
/// be handled, or a 400 shows up in the UI as `[Instance of 'List']`.
String? messageFromBody(Object? body) {
  if (body is! Map) return null;
  final message = body['message'];
  if (message is String && message.trim().isNotEmpty) return message;
  if (message is List && message.isNotEmpty) {
    return message.map((line) => '$line').join('\n');
  }
  final error = body['error'];
  return error is String && error.trim().isNotEmpty ? error : null;
}
