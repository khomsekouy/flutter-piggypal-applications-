import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_piggypal_app/core/error/exceptions.dart';
import 'package:flutter_piggypal_app/core/network/dio_error_mapper.dart';
import 'package:flutter_piggypal_app/core/network/interceptors/auth_interceptor.dart';
import 'package:flutter_piggypal_app/core/network/interceptors/refresh_interceptor.dart';
import 'package:flutter_piggypal_app/features/authentication/data/models/account_deletion_model.dart';
import 'package:flutter_piggypal_app/features/authentication/data/models/auth_session_model.dart';
import 'package:flutter_piggypal_app/features/authentication/data/models/auth_user_model.dart';
import 'package:flutter_piggypal_app/features/authentication/data/models/password_reset_request_model.dart';
import 'package:flutter_piggypal_app/features/authentication/data/models/password_reset_token_model.dart';
import 'package:flutter_piggypal_app/features/authentication/data/models/phone_verification_request_model.dart';
import 'package:flutter_piggypal_app/features/authentication/data/models/phone_verification_token_model.dart';
import 'package:flutter_piggypal_app/features/authentication/data/models/registration_code_request_model.dart';

/// The auth calls, as paths under the configured API base URL.
abstract final class AuthEndpoints {
  AuthEndpoints._();

  static const login = '/auth/login';
  static const register = '/auth/register';
  static const logout = '/auth/logout';

  /// Sign-up step one: texts a code to a number that has no account yet.
  ///
  /// Unguarded, and unguardable — there is no account to sign in to, so the
  /// number has to come from the body. Answers 409 for a number that is
  /// already registered rather than texting it, and is rate-limited to 3 calls
  /// per 15 minutes because every call sends a message somebody pays for.
  static const registerRequestOtp = '/auth/register/request-otp';

  /// Sign-up step two: trades a correct code for the short-lived
  /// `verificationToken` that [register] spends.
  ///
  /// Carries the number again rather than a handle from step one: the code was
  /// issued against the number, so the number is what identifies it.
  static const registerVerifyOtp = '/auth/register/verify-otp';

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

  /// Step one of the password reset: texts a code to the number given.
  ///
  /// Unguarded, and unguardable — the caller has forgotten the password that
  /// would get them a session. It answers 200 with the same body whether or
  /// not the number has an account, so nothing here can be used to find out
  /// which numbers are registered.
  static const forgotPassword = '/auth/forgot-password';

  /// Step two: spends the code and mints a short-lived reset token.
  ///
  /// Also unguarded — the code *is* the credential. Unlike
  /// [confirmPhoneVerification] it takes the number, because there is no
  /// session to read one from.
  static const verifyOtp = '/auth/verify-otp';

  /// Step three: the new password, against the token step two returned.
  ///
  /// Succeeding revokes every session the account had, this device's
  /// included — a reset is the recovery path for a stolen account, so
  /// whoever else was signed in has to be thrown out.
  static const resetPassword = '/auth/reset-password';

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

  /// `POST /auth/register`.
  ///
  /// [verificationToken] is what [verifyRegistrationCode] returned. With one
  /// the account is created with its number already proved; without one the
  /// account is created unverified, which is the older order the server still
  /// accepts. A token that has expired or was already spent comes back as an
  /// [InvalidVerificationCodeException] — the number has to be proved again,
  /// but nothing about the form the user filled in is wrong.
  Future<AuthSessionModel> register({
    required String countryCode,
    required String phone,
    required String password,
    String? verificationToken,
    String? email,
    String? name,
    Uint8List? avatar,
    String? avatarFileName,
    String? deviceId,
    String? deviceName,
    CancelToken? cancelToken,
  });

  /// `POST /auth/register/request-otp` — sign-up step one. Doubles as the
  /// resend: the server retires whatever code was live for the number and
  /// issues a new one either way.
  ///
  /// A number that already has an account is a 409, which arrives as a
  /// [ServerException] carrying the server's own wording — the screen shows it
  /// on the number rather than as a passing message.
  Future<RegistrationCodeRequestModel> requestRegistrationCode({
    required String countryCode,
    required String phone,
    CancelToken? cancelToken,
  });

  /// `POST /auth/register/verify-otp` — sign-up step two.
  ///
  /// Throws [InvalidVerificationCodeException] when the code is wrong,
  /// expired, or the fifth wrong guess: the server answers all of those
  /// identically on purpose, so the app cannot tell them apart either. A
  /// number claimed by somebody else since step one is a 409, as there.
  Future<PhoneVerificationTokenModel> verifyRegistrationCode({
    required String countryCode,
    required String phone,
    required String code,
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

  /// `POST /auth/forgot-password` — step one of the reset.
  ///
  /// Returns normally for a number with no account: the server answers both
  /// cases the same way, and the app must not turn that into a difference the
  /// user can see. Rate-limited to 3 calls per 15 minutes.
  Future<PasswordResetRequestModel> forgotPassword({
    required String countryCode,
    required String phone,
    CancelToken? cancelToken,
  });

  /// `POST /auth/verify-otp` — step two.
  ///
  /// Throws [InvalidVerificationCodeException] when the code is wrong,
  /// expired, spent, or belongs to a number with no account. The server
  /// answers all of those identically on purpose, so the app cannot tell them
  /// apart either.
  Future<PasswordResetTokenModel> verifyOtp({
    required String countryCode,
    required String phone,
    required String code,
    CancelToken? cancelToken,
  });

  /// `POST /auth/reset-password` — step three.
  ///
  /// [resetToken] is what [verifyOtp] returned, and is good for one use
  /// inside ten minutes. Throws [InvalidVerificationCodeException] once it is
  /// past either — see the implementation for why that rather than
  /// [UnauthorizedException].
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
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
    String? verificationToken,
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
    // the same validators an absent one satisfies. An empty `verificationToken`
    // is dropped by the same rule, which is what the server's own `@MinLength`
    // on the field is there to catch.
    final fields = _compact({
      'countryCode': countryCode,
      'phone': phone,
      'password': password,
      'verificationToken': verificationToken,
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

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        AuthEndpoints.register,
        data: body,
        options: _noAuth,
        cancelToken: cancelToken,
      );
      return AuthSessionModel.fromJson(_requireBody(response.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // This route is unguarded, so a 401 here cannot be about a session:
        // the only credential in the request is the verification token, and
        // the server answers with this when it has expired or been spent.
        // Reporting it as an auth failure would tell a user who has no session
        // yet that theirs had expired.
        throw InvalidVerificationCodeException(
          messageFromBody(e.response?.data) ??
              'That verification has expired. Verify your number again.',
        );
      }
      throw mapDioException(e);
    }
  }

  @override
  Future<RegistrationCodeRequestModel> requestRegistrationCode({
    required String countryCode,
    required String phone,
    CancelToken? cancelToken,
  }) async {
    final json = await _post(
      AuthEndpoints.registerRequestOtp,
      body: {'countryCode': countryCode, 'phone': phone},
      cancelToken: cancelToken,
    );
    return RegistrationCodeRequestModel.fromJson(json);
  }

  @override
  Future<PhoneVerificationTokenModel> verifyRegistrationCode({
    required String countryCode,
    required String phone,
    required String code,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        AuthEndpoints.registerVerifyOtp,
        data: {'countryCode': countryCode, 'phone': phone, 'code': code},
        options: _noAuth,
        cancelToken: cancelToken,
      );
      return PhoneVerificationTokenModel.fromJson(_requireBody(response.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // The six digits, not a session — there is no account here yet, which
        // is the whole reason this endpoint is unguarded.
        throw InvalidVerificationCodeException(
          messageFromBody(e.response?.data) ??
              'That code is invalid or has expired.',
        );
      }
      throw mapDioException(e);
    }
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

  @override
  Future<PasswordResetRequestModel> forgotPassword({
    required String countryCode,
    required String phone,
    CancelToken? cancelToken,
  }) async {
    final json = await _post(
      AuthEndpoints.forgotPassword,
      body: {'countryCode': countryCode, 'phone': phone},
      cancelToken: cancelToken,
    );
    return PasswordResetRequestModel.fromJson(json);
  }

  @override
  Future<PasswordResetTokenModel> verifyOtp({
    required String countryCode,
    required String phone,
    required String code,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        AuthEndpoints.verifyOtp,
        data: {'countryCode': countryCode, 'phone': phone, 'code': code},
        options: _noAuth,
        cancelToken: cancelToken,
      );
      return PasswordResetTokenModel.fromJson(_requireBody(response.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // The six digits, not a session — there is no session here to be
        // expired, which is the whole reason this endpoint is unguarded.
        throw InvalidVerificationCodeException(
          messageFromBody(e.response?.data) ??
              'That code is invalid or has expired.',
        );
      }
      throw mapDioException(e);
    }
  }

  @override
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
    CancelToken? cancelToken,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        AuthEndpoints.resetPassword,
        data: {'resetToken': resetToken, 'newPassword': newPassword},
        options: _noAuth,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Not [UnauthorizedException], even though the status is the one an
        // expired access token gets: this 401 is about the reset token, and
        // reporting it as an auth failure would tell a signed-out user their
        // session had expired — and, worse, drop the tokens of a signed-in
        // one who took too long over the form.
        throw InvalidVerificationCodeException(
          messageFromBody(e.response?.data) ??
              'That reset link has expired. Start again.',
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
