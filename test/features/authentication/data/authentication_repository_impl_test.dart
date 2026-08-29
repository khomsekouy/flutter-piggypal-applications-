import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_piggypal_app/core/error/failures.dart';
import 'package:flutter_piggypal_app/core/network/dio_client.dart';
import 'package:flutter_piggypal_app/features/authentication/data/datasources/auth_session_refresher.dart';
import 'package:flutter_piggypal_app/features/authentication/data/datasources/auth_token_store.dart';
import 'package:flutter_piggypal_app/features/authentication/data/datasources/authentication_remote_data_source.dart';
import 'package:flutter_piggypal_app/features/authentication/data/repositories/authentication_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/helpers.dart';

/// Exercises the real repository, data source, interceptors and JSON parsing
/// against [FakeAuthApi] — only the socket is stubbed, so a wrong field name
/// or a mis-shaped response still fails here.
void main() {
  late FakeAuthApi api;
  late InMemoryAuthTokenStore tokens;
  late AuthSessionRefresher refresher;
  late AuthenticationRepositoryImpl repository;

  setUp(() {
    api = FakeAuthApi();
    tokens = InMemoryAuthTokenStore();
    final inner = Dio()..httpClientAdapter = api;
    final remote = AuthenticationRemoteDataSourceImpl(inner);
    refresher = AuthSessionRefresher(remote, tokens);
    // The same client the app builds, refresh-on-401 included.
    buildDio(
      readAccessToken: tokens.readAccessToken,
      refreshSession: (used) => refresher.refresh(usedAccessToken: used),
      dio: inner,
    );
    repository = AuthenticationRepositoryImpl(remote, tokens, refresher);
  });

  tearDown(() => refresher.dispose());

  group('signIn', () {
    test('posts the national number and stores the returned tokens', () async {
      final result = await repository.signIn(
        countryCode: '+855',
        phone: '97573235',
        password: 'Passw0rd!23',
      );

      expect(result.isRight(), isTrue);
      final request = api.requestTo('/auth/login')!;
      expect(request.method, 'POST');
      expect(request.fields['countryCode'], '+855');
      // National only: the API joins the two and rejects a number that
      // already carries its dialling code.
      expect(request.fields['phone'], '97573235');
      expect(request.fields['deviceId'], isNotEmpty);
      // Nothing to authenticate with yet, so no bearer header.
      expect(request.isAuthenticated, isFalse);

      expect(await tokens.readAccessToken(), FakeAuthApi.accessToken);
      expect(await tokens.readRefreshToken(), FakeAuthApi.refreshToken);
    });

    test('maps a 401 onto an AuthFailure and stores nothing', () async {
      api.rejectLogin = true;

      final result = await repository.signIn(
        countryCode: '+855',
        phone: '97573235',
        password: 'wrong',
      );

      expect(
        result.getLeft().toNullable(),
        const AuthFailure('Invalid phone or password'),
      );
      expect(await tokens.readAccessToken(), isNull);
    });
  });

  group('signUp', () {
    test('sends JSON and drops the fields that were not filled in', () async {
      await repository.signUp(
        countryCode: '+855',
        phone: '97573235',
        password: 'Passw0rd!23',
        name: 'KOUY dev',
      );

      final request = api.requestTo('/auth/register')!;
      expect(request.fields['name'], 'KOUY dev');
      // `email` was never collected. Sending it as null would fail the API's
      // strict validation, so it must not be in the body at all.
      expect(request.fields.containsKey('email'), isFalse);
      expect(request.fileParts, isEmpty);
    });

    test('sends the photo as the multipart `avatar` part', () async {
      await repository.signUp(
        countryCode: '+855',
        phone: '97573235',
        password: 'Passw0rd!23',
        name: 'KOUY dev',
        avatar: Uint8List.fromList([1, 2, 3]),
        avatarFileName: 'avatar.png',
      );

      final request = api.requestTo('/auth/register')!;
      // A file part, not an `avatarUrl` field — this API has no such field.
      expect(request.fileParts, ['avatar']);
      expect(request.fields['phone'], '97573235');
    });

    test('signs the new account in straight away', () async {
      await repository.signUp(
        countryCode: '+855',
        phone: '97573235',
        password: 'Passw0rd!23',
      );

      expect(await tokens.readAccessToken(), FakeAuthApi.accessToken);
    });
  });

  group('getCurrentUser', () {
    test('sends the stored token and parses the profile', () async {
      await tokens.saveTokens(
        accessToken: FakeAuthApi.accessToken,
        refreshToken: FakeAuthApi.refreshToken,
      );

      final result = await repository.getCurrentUser();

      final user = result.getRight().toNullable()!;
      expect(user.id, 'user-1');
      expect(user.phone, '+85512345678');
      expect(user.currency, 'USD');
      expect(user.phoneVerified, isTrue);
      expect(user.createdAt, isNotNull);
      expect(api.requestTo('/users/me')!.bearerToken, FakeAuthApi.accessToken);
    });

    test('drops a token the server has rejected', () async {
      await tokens.saveTokens(accessToken: 'stale', refreshToken: 'stale');
      api.rejectCurrentUser = true;

      final result = await repository.getCurrentUser();

      expect(result.getLeft().toNullable(), isA<AuthFailure>());
      // Keeping it would mean presenting a credential we know is dead on
      // every later request.
      expect(await tokens.readAccessToken(), isNull);
    });
  });

  group('phone verification', () {
    /// A fresh, unverified account — the state the verification screens are
    /// reached in.
    Future<void> signUp() async {
      api.phoneVerified = false;
      await repository.signIn(
        countryCode: '+855',
        phone: '97573235',
        password: 'Passw0rd!23',
      );
    }

    test('asks for a code with the session and no number', () async {
      await signUp();

      final result = await repository.requestPhoneVerification();

      final request = api.requestTo('/auth/verify-phone/request')!;
      expect(request.isAuthenticated, isTrue);
      // The number is the server's to know: an endpoint that accepted one
      // would be an endpoint for texting strangers.
      expect(request.fields, isEmpty);
      expect(
        result.getRight().toNullable()?.alreadyVerified,
        isFalse,
      );
    });

    test('reports a number that needed no code', () async {
      await signUp();
      api.phoneVerified = true;

      final result = await repository.requestPhoneVerification();

      expect(result.getRight().toNullable()?.alreadyVerified, isTrue);
    });

    test('a correct code verifies the number', () async {
      await signUp();
      await repository.requestPhoneVerification();

      final result = await repository.confirmPhoneVerification(
        code: api.mockCode,
      );

      expect(result.isRight(), isTrue);
      expect(
        api.requestTo('/auth/verify-phone/confirm')!.fields['code'],
        api.mockCode,
      );
    });

    test(
      'a rejected code is a VerificationFailure, not an AuthFailure',
      () async {
        await signUp();
        await repository.requestPhoneVerification();

        final result = await repository.confirmPhoneVerification(
          code: '000000',
        );

        final failure = result.getLeft().toNullable();
        // The distinction that matters: an AuthFailure here would sign the user
        // out over a typo. The session is untouched.
        expect(failure, isA<VerificationFailure>());
        expect(failure, isNot(isA<AuthFailure>()));
        expect(await tokens.readAccessToken(), isNotNull);
      },
    );

    test('a rejected code is never refreshed and retried', () async {
      await signUp();
      await repository.requestPhoneVerification();

      await repository.confirmPhoneVerification(code: '000000');

      // The server counts an attempt *before* it compares, so a replay would
      // spend two of the five guesses the user gets — and rotate the refresh
      // token for nothing.
      final attempts = api.requests
          .where((r) => r.path.endsWith('/auth/verify-phone/confirm'))
          .length;
      expect(attempts, 1);
      expect(api.rotations, 0);
    });
  });

  group('refresh on 401', () {
    Future<void> signIn() => repository.signIn(
      countryCode: '+855',
      phone: '97573235',
      password: 'Passw0rd!23',
    );

    test('an expired access token is rotated and the call retried', () async {
      await signIn();
      api.expireAccessToken();

      final result = await repository.getCurrentUser();

      // The caller never sees the 401.
      expect(result.isRight(), isTrue);
      expect(api.rotations, 1);
      // Both halves of the pair are replaced — the API rotates the refresh
      // token too, and keeping the old one would look like a leak next time.
      expect(await tokens.readAccessToken(), api.liveAccessToken);
      expect(await tokens.readRefreshToken(), api.liveRefreshToken);
      // Two attempts at /users/me: the 401 and the replay.
      expect(
        api.requests.where((r) => r.path.endsWith('/users/me')).length,
        2,
      );
    });

    test('concurrent 401s share one rotation', () async {
      await signIn();
      api.expireAccessToken();

      final results = await Future.wait([
        repository.getCurrentUser(),
        repository.getCurrentUser(),
        repository.getCurrentUser(),
      ]);

      expect(results.every((r) => r.isRight()), isTrue);
      // The whole point: a second call with a spent refresh token is read
      // server-side as a leak and drops every session the account has.
      expect(api.rotations, 1);
      expect(api.reuseDetected, isFalse);
      expect(
        api.requests.where((r) => r.path.endsWith('/auth/refresh')).length,
        1,
      );
    });

    test('a rejected refresh ends the session and says so', () async {
      await signIn();
      api
        ..expireAccessToken()
        ..rejectRefresh = true;
      final expired = expectLater(refresher.sessionExpired, emits(anything));

      final result = await repository.getCurrentUser();

      expect(result.getLeft().toNullable(), isA<AuthFailure>());
      expect(await tokens.readAccessToken(), isNull);
      expect(await tokens.readRefreshToken(), isNull);
      await expired;
    });

    test('a refresh that cannot be sent leaves the session intact', () async {
      await signIn();
      api.expireAccessToken();
      final storedRefresh = await tokens.readRefreshToken();
      api.offline = true;

      final result = await repository.getCurrentUser();

      // The request fails, but a dropped connection is not a dead session:
      // clearing the tokens here would sign the user out over a flaky network.
      expect(result.isLeft(), isTrue);
      expect(await tokens.readRefreshToken(), storedRefresh);
    });

    test('a 401 from sign-in itself is never refreshed', () async {
      api.rejectLogin = true;

      await repository.signIn(
        countryCode: '+855',
        phone: '97573235',
        password: 'wrong',
      );

      // Refreshing a failed sign-in would be a loop with nothing to rotate.
      expect(api.called('/auth/refresh'), isFalse);
    });
  });

  group('signOut', () {
    test('revokes the session server-side, then forgets the tokens', () async {
      await tokens.saveTokens(
        accessToken: FakeAuthApi.accessToken,
        refreshToken: FakeAuthApi.refreshToken,
      );

      final result = await repository.signOut();

      expect(result.isRight(), isTrue);
      expect(
        api.requestTo('/auth/logout')!.fields['refreshToken'],
        FakeAuthApi.refreshToken,
      );
      expect(await tokens.readAccessToken(), isNull);
      expect(await tokens.readRefreshToken(), isNull);
    });

    test('still signs out locally when the call cannot be made', () async {
      await tokens.saveTokens(
        accessToken: 'a',
        refreshToken: 'r',
      );
      api.offline = true;

      final result = await repository.signOut();

      // A flaky connection must not be able to keep someone signed in.
      expect(result.isRight(), isTrue);
      expect(await tokens.readRefreshToken(), isNull);
    });

    test('skips the call when there is no session to revoke', () async {
      await repository.signOut();

      expect(api.called('/auth/logout'), isFalse);
    });
  });

  group('hasSession', () {
    test('is false until a sign-in stores a token', () async {
      expect(await repository.hasSession(), isFalse);

      await repository.signIn(
        countryCode: '+855',
        phone: '97573235',
        password: 'Passw0rd!23',
      );

      expect(await repository.hasSession(), isTrue);
    });
  });
}
