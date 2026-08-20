import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_piggypal_app/core/error/exceptions.dart';
import 'package:flutter_piggypal_app/core/network/dio_error_mapper.dart';
import 'package:flutter_piggypal_app/core/network/interceptors/auth_interceptor.dart';
import 'package:flutter_piggypal_app/core/network/interceptors/refresh_interceptor.dart';
import 'package:flutter_piggypal_app/features/authentication/data/models/auth_session_model.dart';
import 'package:flutter_piggypal_app/features/authentication/data/models/auth_user_model.dart';

/// The four auth calls, as paths under the configured API base URL.
abstract final class AuthEndpoints {
  AuthEndpoints._();

  static const login = '/auth/login';
  static const register = '/auth/register';
  static const logout = '/auth/logout';

  /// Trades a refresh token for a new pair. The old one is retired by the
  /// server the moment this succeeds.
  static const refresh = '/auth/refresh';

  /// `/users/me`, not `/auth/me`: the latter only echoes the token's claims,
  /// while this reads the row and so carries the avatar, currency, verified
  /// flags and join date the profile screens show.
  static const currentUser = '/users/me';
}

/// Talks to the PiggyPal mobile API. Throws; the repository maps to `Failure`s.
///
/// Every method takes an optional [CancelToken] so a screen that goes away
/// mid-request can abort it instead of waiting for a response nobody will use.
abstract interface class AuthenticationRemoteDataSource {
  Future<AuthSessionModel> login({
    required String countryCode,
    required String phone,
    required String password,
    String? deviceId,
    String? deviceName,
    CancelToken? cancelToken,
  });

  Future<AuthSessionModel> register({
    required String countryCode,
    required String phone,
    required String password,
    String? email,
    String? name,
    Uint8List? avatar,
    String? avatarFileName,
    String? deviceId,
    String? deviceName,
    CancelToken? cancelToken,
  });

  /// `POST /auth/refresh`. Returns a **new** access *and* refresh token: the
  /// server rotates on every call, so the token passed in is dead afterwards
  /// and the reply must be stored before anything else uses it.
  Future<AuthSessionModel> refresh({
    required String refreshToken,
    String? deviceId,
    String? deviceName,
    CancelToken? cancelToken,
  });

  Future<void> logout({
    required String refreshToken,
    CancelToken? cancelToken,
  });

  Future<AuthUserModel> getCurrentUser({CancelToken? cancelToken});
}

class AuthenticationRemoteDataSourceImpl
    implements AuthenticationRemoteDataSource {
  const AuthenticationRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  /// The unguarded routes: they either mint a session or spend a refresh
  /// token, so an expired access token must not make them fail — and a 401
  /// from one of them is final, not something a refresh could fix. Refreshing
  /// on a failed refresh would loop.
  static final _noAuth = Options(
    extra: {
      AuthInterceptor.skipAuth: true,
      RefreshInterceptor.skipRefresh: true,
    },
  );

  @override
  Future<AuthSessionModel> login({
    required String countryCode,
    required String phone,
    required String password,
    String? deviceId,
    String? deviceName,
    CancelToken? cancelToken,
  }) async {
    final json = await _post(
      AuthEndpoints.login,
      body: _compact({
        'countryCode': countryCode,
        'phone': phone,
        'password': password,
        'deviceId': deviceId,
        'deviceName': deviceName,
      }),
      cancelToken: cancelToken,
    );
    return AuthSessionModel.fromJson(json);
  }

  @override
  Future<AuthSessionModel> register({
    required String countryCode,
    required String phone,
    required String password,
    String? email,
    String? name,
    Uint8List? avatar,
    String? avatarFileName,
    String? deviceId,
    String? deviceName,
    CancelToken? cancelToken,
  }) async {
    // Null fields are dropped rather than sent as null: the API validates with
    // `forbidNonWhitelisted`, and an explicit null on an optional field fails
    // the same validators an absent one satisfies.
    final fields = _compact({
      'countryCode': countryCode,
      'phone': phone,
      'password': password,
      'email': email,
      'name': name,
      'deviceId': deviceId,
      'deviceName': deviceName,
    });

    // The photo travels as a `avatar` file part — this API has no `avatarUrl`
    // field to post, by design, and would reject one. No photo, no multipart:
    // the same fields go out as plain JSON.
    final body = avatar == null
        ? fields
        : FormData.fromMap({
            ...fields,
            'avatar': MultipartFile.fromBytes(
              avatar,
              filename: avatarFileName ?? 'avatar.jpg',
            ),
          });

    final json = await _post(
      AuthEndpoints.register,
      body: body,
      cancelToken: cancelToken,
    );
    return AuthSessionModel.fromJson(json);
  }

  @override
  Future<AuthSessionModel> refresh({
    required String refreshToken,
    String? deviceId,
    String? deviceName,
    CancelToken? cancelToken,
  }) async {
    final json = await _post(
      AuthEndpoints.refresh,
      body: _compact({
        'refreshToken': refreshToken,
        'deviceId': deviceId,
        'deviceName': deviceName,
      }),
      cancelToken: cancelToken,
    );
    return AuthSessionModel.fromJson(json);
  }

  @override
  Future<void> logout({
    required String refreshToken,
    CancelToken? cancelToken,
  }) async {
    await _post(
      AuthEndpoints.logout,
      body: {'refreshToken': refreshToken},
      cancelToken: cancelToken,
    );
  }

  @override
  Future<AuthUserModel> getCurrentUser({CancelToken? cancelToken}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        AuthEndpoints.currentUser,
        cancelToken: cancelToken,
      );
      return AuthUserModel.fromJson(_requireBody(response.data));
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    required Object body,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: body,
        options: _noAuth,
        cancelToken: cancelToken,
      );
      return _requireBody(response.data);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// A 2xx with no JSON body means the app is pointed at something that is not
  /// this API — a proxy, a login portal, the wrong port.
  Map<String, dynamic> _requireBody(Map<String, dynamic>? data) {
    if (data == null) {
      throw const ServerException('The server returned an empty response.');
    }
    return data;
  }

  Map<String, String> _compact(Map<String, String?> values) => {
    for (final entry in values.entries)
      if (entry.value != null && entry.value!.isNotEmpty)
        entry.key: entry.value!,
  };
}
