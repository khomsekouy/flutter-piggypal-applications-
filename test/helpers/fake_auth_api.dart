import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// One request the app made, kept so a test can assert on it.
class FakeRequest {
  const FakeRequest(this.method, this.path, this.headers, this.body);

  final String method;
  final String path;
  final Map<String, dynamic> headers;

  /// Exactly what was handed to dio: a `Map` for a JSON body, a [FormData]
  /// for a multipart one.
  final Object? body;

  bool get isAuthenticated => headers['Authorization'] != null;

  String? get bearerToken {
    final header = headers['Authorization'];
    return header is String ? header.replaceFirst('Bearer ', '') : null;
  }

  /// The JSON body's fields, or the multipart form's text parts — so a test
  /// can assert on what was sent without caring which encoding was used.
  Map<String, String> get fields => switch (body) {
    final Map<String, dynamic> map => {
      for (final entry in map.entries) entry.key: '${entry.value}',
    },
    final FormData form => {
      for (final field in form.fields) field.key: field.value,
    },
    _ => const {},
  };

  /// Names of the multipart file parts, empty for a JSON body.
  List<String> get fileParts => switch (body) {
    final FormData form => [for (final file in form.files) file.key],
    _ => const [],
  };
}

/// Stands in for the PiggyPal mobile API.
///
/// Installed as the [Dio] adapter, so the app's own interceptors, error
/// mapping and JSON parsing all run for real — only the socket is replaced.
/// That is the difference from mocking the repository: a broken request body
/// or a mis-shaped response still fails the test.
class FakeAuthApi implements HttpClientAdapter {
  /// Every request made, in order.
  final List<FakeRequest> requests = <FakeRequest>[];

  /// Flip to make `POST /auth/login` answer 401, as a wrong password does.
  bool rejectLogin = false;

  /// Flip to make `GET /users/me` answer 401 whatever token is presented.
  bool rejectCurrentUser = false;

  /// Flip to make `POST /auth/refresh` reject the token, as an expired or
  /// revoked one does.
  bool rejectRefresh = false;

  /// Flip to make every call fail the way an unreachable server does.
  bool offline = false;

  /// Whether the account's number is already proved. Sign-up leaves this
  /// false, which is what sends a new account to the verification screens.
  bool phoneVerified = true;

  /// The only code `/auth/verify-phone/confirm` accepts. Mirrors the real
  /// API's `OTP_MOCK_CODE`, which is also what makes it echo `devCode`.
  String mockCode = '123456';

  /// Flip to make `verify-phone/request` answer 429, as the real API does on
  /// the fourth send inside fifteen minutes.
  bool throttleCodeRequests = false;

  /// How many codes were asked for.
  int codeRequests = 0;

  /// Flip to make `PATCH /users/me` refuse the picture, as an unstorable or
  /// oversized file does.
  bool rejectAvatarUpload = false;

  /// The name on the account. Nullable, because the API's own `name` is —
  /// registering with a number and a password alone is allowed.
  String? userName = 'Test User';

  /// Set by a successful avatar upload, and what the returned profile then
  /// carries — so a test can tell an upload that landed from one that did not.
  String? avatarUrl;

  static const accessToken = 'test-access-token';
  static const refreshToken = 'test-refresh-token';

  /// The pair the server currently accepts. Sign-in resets them; refreshing
  /// rotates them, exactly as the real API does.
  String liveAccessToken = accessToken;
  String liveRefreshToken = refreshToken;

  /// Refresh tokens that have been rotated away. Presenting one again is what
  /// the real API reads as a leak — it then drops every session.
  final Set<String> retiredRefreshTokens = <String>{};

  /// True once a retired refresh token was presented.
  bool reuseDetected = false;

  int rotations = 0;

  /// Makes the token the client is holding stale, the way a 15-minute expiry
  /// does, without telling the client.
  void expireAccessToken() => liveAccessToken = 'server-rotated-access-token';

  Map<String, dynamic> get user => <String, dynamic>{
    'id': 'user-1',
    'phone': '+85512345678',
    'email': 'test@piggypal.test',
    'name': userName,
    'avatarUrl': avatarUrl,
    'currency': 'USD',
    'status': 'active',
    'phoneVerified': phoneVerified,
    'emailVerified': false,
    'createdAt': '2026-01-15T08:00:00.000Z',
  };

  FakeRequest? requestTo(String path) {
    for (final request in requests) {
      if (request.path.endsWith(path)) return request;
    }
    return null;
  }

  bool called(String path) => requestTo(path) != null;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path;
    if (offline) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'Connection refused',
      );
    }
    requests.add(
      FakeRequest(options.method, path, options.headers, options.data),
    );

    if (path.endsWith('/auth/login')) {
      if (rejectLogin) {
        return _json({
          'message': 'Invalid phone or password',
          'error': 'Unauthorized',
          'statusCode': 401,
        }, 401);
      }
      _resetSession();
      return _json(_session('Signed in successfully'), 200);
    }
    if (path.endsWith('/auth/register')) {
      _resetSession();
      return _json(_session('Account created successfully'), 201);
    }
    if (path.endsWith('/auth/refresh')) {
      return _refresh(options.data);
    }
    if (path.endsWith('/auth/logout')) {
      return _json({'message': 'Signed out successfully'}, 200);
    }
    if (path.endsWith('/auth/verify-phone/request')) {
      return _requestPhoneVerification(options);
    }
    if (path.endsWith('/auth/verify-phone/confirm')) {
      return _confirmPhoneVerification(options);
    }
    if (path.endsWith('/users/me')) {
      final presented = options.headers['Authorization'];
      final accepted =
          !rejectCurrentUser && presented == 'Bearer $liveAccessToken';
      if (!accepted) {
        return _json({'message': 'Unauthorized', 'statusCode': 401}, 401);
      }
      if (options.method == 'PATCH') {
        if (rejectAvatarUpload) {
          return _json({
            'message': 'Avatar could not be stored',
            'error': 'Bad Request',
            'statusCode': 400,
          }, 400);
        }
        avatarUrl = 'https://piggypal.test/uploads/avatar.jpg';
      }
      return _json(user, 200);
    }

    return _json({
      'message': 'Cannot ${options.method} $path',
      'error': 'Not Found',
      'statusCode': 404,
    }, 404);
  }

  /// Guarded, so an unusable token is a 401 before anything else is looked
  /// at — the same order the real `JwtAuthGuard` works in.
  ResponseBody? _rejectIfUnauthenticated(RequestOptions options) {
    if (options.headers['Authorization'] == 'Bearer $liveAccessToken') {
      return null;
    }
    return _json({'message': 'Unauthorized', 'statusCode': 401}, 401);
  }

  ResponseBody _requestPhoneVerification(RequestOptions options) {
    final rejected = _rejectIfUnauthenticated(options);
    if (rejected != null) return rejected;

    if (throttleCodeRequests) {
      return _json({
        'message': 'ThrottlerException: Too Many Requests',
        'statusCode': 429,
      }, 429);
    }
    if (phoneVerified) {
      // No code sent: the real API will not spend a message re-proving a
      // number it has already proved.
      return _json({
        'message': 'Phone is already verified',
        'phoneVerified': true,
      }, 200);
    }

    codeRequests++;
    return _json({
      'message': 'A verification code was sent',
      'phoneVerified': false,
      // Echoed only because codes are mocked, exactly as the API does.
      'devCode': mockCode,
    }, 200);
  }

  ResponseBody _confirmPhoneVerification(RequestOptions options) {
    final rejected = _rejectIfUnauthenticated(options);
    if (rejected != null) return rejected;

    final body = options.data;
    final code = body is Map ? '${body['code']}' : '';
    if (code != mockCode) {
      // 401, the same status an expired access token gets — which is why the
      // client has to tell the two apart by more than the status.
      return _json({
        'message': 'Verification code is invalid or expired',
        'error': 'Unauthorized',
        'statusCode': 401,
      }, 401);
    }

    phoneVerified = true;
    return _json({
      'message': 'Phone verified successfully',
      'phoneVerified': true,
    }, 200);
  }

  /// `POST /auth/refresh`, rotation and reuse detection included — the two
  /// behaviours the client has to get right.
  ResponseBody _refresh(Object? body) {
    final presented = body is Map ? '${body['refreshToken']}' : '';

    if (retiredRefreshTokens.contains(presented)) {
      // The real API drops every session for the account here.
      reuseDetected = true;
      liveAccessToken = 'revoked';
      liveRefreshToken = 'revoked';
      return _json({
        'message': 'Refresh token reuse detected',
        'error': 'Unauthorized',
        'statusCode': 401,
      }, 401);
    }

    if (rejectRefresh || presented != liveRefreshToken) {
      return _json({
        'message': 'Invalid refresh token',
        'error': 'Unauthorized',
        'statusCode': 401,
      }, 401);
    }

    rotations++;
    retiredRefreshTokens.add(presented);
    liveAccessToken = 'access-token-$rotations';
    liveRefreshToken = 'refresh-token-$rotations';

    // No `message` field — the real refresh response has none.
    return _json({
      'accessToken': liveAccessToken,
      'refreshToken': liveRefreshToken,
      'user': user,
    }, 200);
  }

  void _resetSession() {
    liveAccessToken = accessToken;
    liveRefreshToken = refreshToken;
    retiredRefreshTokens.clear();
  }

  Map<String, dynamic> _session(String message) => {
    'message': message,
    'accessToken': liveAccessToken,
    'refreshToken': liveRefreshToken,
    'user': user,
  };

  ResponseBody _json(Map<String, dynamic> body, int status) =>
      ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}
