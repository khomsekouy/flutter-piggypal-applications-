import 'package:dio/dio.dart';
import 'package:flutter_piggypal_app/core/error/exceptions.dart';
import 'package:flutter_piggypal_app/core/network/dio_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

/// A 429 as the API sends it: the throttler's own body, and `Retry-After`
/// only when [retryAfter] is given.
DioException _throttled({String? retryAfter}) {
  final options = RequestOptions(path: '/auth/verify-phone/request');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: 429,
      data: const {
        'message': 'ThrottlerException: Too Many Requests',
        'statusCode': 429,
      },
      headers: Headers.fromMap({
        if (retryAfter != null) 'retry-after': [retryAfter],
      }),
    ),
  );
}

void main() {
  group('mapDioException on a 429', () {
    test('never shows the throttler class name', () {
      final result = mapDioException(_throttled()) as ServerException;

      expect(result.message, isNot(contains('ThrottlerException')));
      expect(result.message, contains('Too many attempts'));
      expect(result.statusCode, 429);
    });

    test('names the wait in seconds when Retry-After is under a minute', () {
      final result = mapDioException(_throttled(retryAfter: '45'));

      expect(
        (result as ServerException).message,
        'Too many attempts. Try again in 45 seconds.',
      );
    });

    test('rounds the wait up to whole minutes', () {
      final result = mapDioException(_throttled(retryAfter: '61'));

      // 61s is two minutes here, not one: rounding down would send the user
      // back a second early, into another 429.
      expect(
        (result as ServerException).message,
        'Too many attempts. Try again in 2 minutes.',
      );
    });

    test('singularises a one-minute wait', () {
      final result = mapDioException(_throttled(retryAfter: '60'));

      expect(
        (result as ServerException).message,
        'Too many attempts. Try again in 1 minute.',
      );
    });

    test('falls back to the vague wording without a usable header', () {
      const generic = 'Too many attempts. Please wait a few minutes and '
          'try again.';

      // Absent, an HTTP-date, and a non-positive count all land here.
      expect(
        (mapDioException(_throttled()) as ServerException).message,
        generic,
      );
      const httpDate = 'Wed, 21 Oct 2026 07:28:00 GMT';
      expect(
        (mapDioException(_throttled(retryAfter: httpDate)) as ServerException)
            .message,
        generic,
      );
      expect(
        (mapDioException(_throttled(retryAfter: '0')) as ServerException)
            .message,
        generic,
      );
    });

    test('does not throw when Retry-After arrives twice', () {
      final options = RequestOptions(path: '/auth/verify-phone/request');
      final duplicated = DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: 429,
          headers: Headers.fromMap({
            'retry-after': ['30', '30'],
          }),
        ),
      );

      expect(mapDioException(duplicated), isA<ServerException>());
    });
  });

  test("other statuses still surface the API's own message", () {
    final options = RequestOptions(path: '/auth/register');
    final conflict = DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(
        requestOptions: options,
        statusCode: 409,
        data: const {'message': 'Phone is already registered'},
      ),
    );

    final result = mapDioException(conflict) as ServerException;

    expect(result.message, 'Phone is already registered');
    expect(result.statusCode, 409);
  });
}
