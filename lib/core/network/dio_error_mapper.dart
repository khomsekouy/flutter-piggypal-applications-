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
      return ServerException(
        message ?? 'The server could not complete that request.',
        statusCode: status,
      );
  }
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
