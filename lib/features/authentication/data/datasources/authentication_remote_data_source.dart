import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_piggypal_app/core/error/exceptions.dart';
import 'package:flutter_piggypal_app/core/network/dio_error_mapper.dart';
import 'package:flutter_piggypal_app/core/network/interceptors/auth_interceptor.dart';
import 'package:flutter_piggypal_app/core/network/interceptors/refresh_interceptor.dart';
import 'package:flutter_piggypal_app/features/authentication/data/models/account_deletion_model.dart';
import 'package:flutter_piggypal_app/features/authentication/data/models/auth_session_model.dart';
import 'package:flutter_piggypal_app/features/authentication/data/models/auth_user_model.dart';
import 'package:flutter_piggypal_app/features/authentication/data/models/phone_verification_request_model.dart';

/// The auth calls, as paths under the configured API base URL.
abstract final class AuthEndpoints {
  AuthEndpoints._();

  static const login = '/auth/login';
  static const register = '/auth/register';
  static const logout = '/auth/logout';

  /// Trades a refresh token for a new pair. The old one is retired by the
  /// server the moment this succeeds.
  static const refresh = '/auth/refresh';

  /// Soft-deletes the signed-in account and revokes every session it has.
  /// `POST`, not `DELETE`: the password rides in the body, and plenty of
  /// mobile HTTP clients quietly drop a body from a DELETE.
  static const deleteAccount = '/auth/delete-account';

  /// Brings a soft-deleted account back and signs it in. Unguarded of
  /// necessity — deletion revoked every token, so the password is the only
  /// credential the caller still holds.
  static const restoreAccount = '/auth/restore-account';

  /// Sends a code to the number on the caller's own account. Guarded, and it
  /// takes no body: the server reads the number off the access token rather
  /// than accepting one, so this cannot be used to text a stranger.
  static const requestPhoneVerification = '/auth/verify-phone/request';

  /// Spends the code and marks the account's number proved.
  static const confirmPhoneVerification = '/auth/verify-phone/confirm';

  /// `/users/me`, not `/auth/me`: the latter only echoes the token's claims,
  /// while this reads the row and so carries the avatar, currency, verified
  /// flags and join date the profile screens show.
  ///
  /// `PATCH` to the same path edits it — including the profile picture, which
  /// travels as a multipart `avatar` file part.
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

  /// `POST /auth/delete-account`.
  ///
  /// Takes the password again on purpose: the access token alone must not be
  /// enough to destroy an account, since a borrowed or stolen session would
  /// then be able to. A 401 here is therefore about the *password*, not the
  /// session — but unlike the verification code, this one is worth refreshing
  /// and replaying, because an expired token would otherwise report a correct
  /// password as wrong on the one action that cannot be undone.
  Future<AccountDeletionModel> deleteAccount({
    required String password,
    CancelToken? cancelToken,
  });

  /// `POST /auth/restore-account`. Answers with a full session, like sign-in.
  Future<AuthSessionModel> restoreAccount({
    required String countryCode,
    required String phone,
    required String password,
    String? deviceId,
    String? deviceName,
    CancelToken? cancelToken,
  });

  Future<AuthUserModel> getCurrentUser({CancelToken? cancelToken});

  /// `PATCH /users/me` with the picture as a multipart `avatar` part.
  ///
  /// A file part and only a file part: this API has no `avatarUrl` field to
  /// post and refuses a part by that name, since the picture stopped being a
  /// link the moment it became an upload. Returns the updated profile.
  Future<AuthUserModel> updateProfilePhoto({
    required Uint8List avatar,
    String? avatarFileName,
    CancelToken? cancelToken,
  });

  /// `POST /auth/verify-phone/request` — texts a fresh 6-digit code to the
  /// number on the signed-in account, retiring whatever code was live.
  ///
  /// The server rate-limits this to 3 calls per 15 minutes, so a rejection
  /// here is as likely to be "too many" as anything else.
  Future<PhoneVerificationRequestModel> requestPhoneVerification({
    CancelToken? cancelToken,
  });

  /// `POST /auth/verify-phone/confirm`.
  ///
  /// Throws [InvalidVerificationCodeException] when the code is wrong,
  /// expired, or the fifth wrong guess — the server answers all of those the
  /// same way on purpose, so the app cannot tell them apart either.
  Future<void> confirmPhoneVerification({
    required String code,
    CancelToken? cancelToken,
  });
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
  Future<AccountDeletionModel> deleteAccount({
    required String password,
    CancelToken? cancelToken,
  }) async {
    try {
      // Guarded, so no `_noAuth` here — and deliberately no `skipRefresh`
      // either: see the interface. A wrong password costs one extra rotation
      // and one throttle slot; an expired token silently refusing a real
      // deletion would cost the user their trust in the button.
      final response = await _dio.post<Map<String, dynamic>>(
        AuthEndpoints.deleteAccount,
        data: {'password': password},
        cancelToken: cancelToken,
      );
      return AccountDeletionModel.fromJson(_requireBody(response.data));
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<AuthSessionModel> restoreAccount({
    required String countryCode,
    required String phone,
    required String password,
    String? deviceId,
    String? deviceName,
    CancelToken? cancelToken,
  }) async {
    final json = await _post(
      AuthEndpoints.restoreAccount,
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

  @override
  Future<AuthUserModel> updateProfilePhoto({
    required Uint8List avatar,
    String? avatarFileName,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        AuthEndpoints.currentUser,
        data: FormData.fromMap({
          'avatar': MultipartFile.fromBytes(
            avatar,
            filename: avatarFileName ?? 'avatar.jpg',
          ),
        }),
        cancelToken: cancelToken,
      );
      return AuthUserModel.fromJson(_requireBody(response.data));
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<PhoneVerificationRequestModel> requestPhoneVerification({
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        AuthEndpoints.requestPhoneVerification,
        cancelToken: cancelToken,
      );
      return PhoneVerificationRequestModel.fromJson(
        _requireBody(response.data),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> confirmPhoneVerification({
    required String code,
    CancelToken? cancelToken,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        AuthEndpoints.confirmPhoneVerification,
        data: {'code': code},
        // A 401 here means the six digits, not the token — so no refresh, and
        // no replay. The replay is the real problem: the server counts an
        // attempt *before* it compares, so retrying a wrong code would spend
        // two of the five guesses the user gets, and rotate the refresh token
        // for nothing.
        //
        // That leaves an expired access token looking like a bad code, which
        // it cannot be here: the request that sent this code refreshed
        // normally moments ago, and a 15-minute access token outlives the
        // 10-minute code it was minted alongside.
        options: Options(extra: {RefreshInterceptor.skipRefresh: true}),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw InvalidVerificationCodeException(
          messageFromBody(e.response?.data) ??
              'That code is invalid or has expired.',
        );
      }
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
