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

  static const user = <String, dynamic>{
    'id': 'user-1',
    'phone': '+85512345678',
    'email': 'test@piggypal.test',
    'name': 'Test User',
    'avatarUrl': null,
    'currency': 'USD',
    'status': 'active',
    'phoneVerified': true,
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
    if (path.endsWith('/users/me')) {
      final presented = options.headers['Authorization'];
      final accepted =
          !rejectCurrentUser && presented == 'Bearer $liveAccessToken';
      return accepted
          ? _json(user, 200)
          : _json({'message': 'Unauthorized', 'statusCode': 401}, 401);
    }

    return _json({
      'message': 'Cannot ${options.method} $path',
      'error': 'Not Found',
      'statusCode': 404,
    }, 404);
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
