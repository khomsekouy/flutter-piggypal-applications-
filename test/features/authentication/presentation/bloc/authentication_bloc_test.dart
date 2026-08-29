import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_piggypal_app/core/network/dio_client.dart';
import 'package:flutter_piggypal_app/features/authentication/data/datasources/auth_session_refresher.dart';
import 'package:flutter_piggypal_app/features/authentication/data/datasources/auth_token_store.dart';
import 'package:flutter_piggypal_app/features/authentication/data/datasources/authentication_remote_data_source.dart';
import 'package:flutter_piggypal_app/features/authentication/data/repositories/authentication_repository_impl.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/get_current_user.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/sign_in.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/sign_out.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/sign_up.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/update_profile_photo.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/helpers.dart';

void main() {
  late FakeAuthApi api;
  late InMemoryAuthTokenStore tokens;
  late AuthSessionRefresher refresher;
  late AuthenticationRepository repository;

  AuthenticationBloc buildBloc() => AuthenticationBloc(
    signIn: SignIn(repository),
    signUp: SignUp(repository),
    signOut: SignOut(repository),
    getCurrentUser: GetCurrentUser(repository),
    updateProfilePhoto: UpdateProfilePhoto(repository),
    repository: repository,
  );

  setUp(() {
    api = FakeAuthApi();
    tokens = InMemoryAuthTokenStore();
    final inner = Dio()..httpClientAdapter = api;
    final remote = AuthenticationRemoteDataSourceImpl(inner);
    refresher = AuthSessionRefresher(remote, tokens);
    buildDio(
      readAccessToken: tokens.readAccessToken,
      refreshSession: (used) => refresher.refresh(usedAccessToken: used),
      dio: inner,
    );
    repository = AuthenticationRepositoryImpl(remote, tokens, refresher);
  });

  tearDown(() => refresher.dispose());

  group('AuthenticationStarted', () {
    blocTest<AuthenticationBloc, AuthenticationState>(
      'is unauthenticated with no stored token, without calling the API',
      build: buildBloc,
      wait: const Duration(milliseconds: 100),
      act: (bloc) => bloc.add(const AuthenticationStarted()),
      expect: () => [
        const AuthenticationState(
          status: AuthenticationStatus.unauthenticated,
        ),
      ],
      verify: (_) => expect(api.called('/users/me'), isFalse),
    );

    blocTest<AuthenticationBloc, AuthenticationState>(
      'confirms a stored token against /users/me',
      setUp: () => tokens.saveTokens(
        accessToken: FakeAuthApi.accessToken,
        refreshToken: FakeAuthApi.refreshToken,
      ),
      build: buildBloc,
      wait: const Duration(milliseconds: 100),
      act: (bloc) => bloc.add(const AuthenticationStarted()),
      expect: () => [
        const AuthenticationState(status: AuthenticationStatus.loading),
        isA<AuthenticationState>()
            .having(
              (s) => s.status,
              'status',
              AuthenticationStatus.authenticated,
            )
            .having((s) => s.user?.name, 'user', 'Test User'),
      ],
    );

    blocTest<AuthenticationBloc, AuthenticationState>(
      'falls back to unauthenticated when the stored token is stale',
      setUp: () async {
        await tokens.saveTokens(accessToken: 'stale', refreshToken: 'stale');
        api.rejectCurrentUser = true;
      },
      build: buildBloc,
      wait: const Duration(milliseconds: 100),
      act: (bloc) => bloc.add(const AuthenticationStarted()),
      // `containsAllInOrder`, because the interceptor's failed refresh and the
      // launch check itself land independently — the order of the two
      // unauthenticated emissions is a race, and only the last one matters.
      expect: () => containsAllInOrder([
        const AuthenticationState(status: AuthenticationStatus.loading),
        const AuthenticationState(
          status: AuthenticationStatus.unauthenticated,
          errorMessage: 'Your session has expired. Please sign in again.',
        ),
      ]),
      verify: (bloc) {
        // A stale token is spent on one refresh attempt, then dropped.
        expect(api.called('/auth/refresh'), isTrue);
        expect(bloc.state.errorMessage, isNotNull);
      },
    );
  });

  group('sign in', () {
    blocTest<AuthenticationBloc, AuthenticationState>(
      'ends authenticated and carries the user',
      build: buildBloc,
      wait: const Duration(milliseconds: 100),
      act: (bloc) => bloc.add(
        const AuthenticationSignInRequested(
          countryCode: '+855',
          phone: '97573235',
          password: 'Passw0rd!23',
        ),
      ),
      expect: () => [
        const AuthenticationState(status: AuthenticationStatus.loading),
        isA<AuthenticationState>()
            .having((s) => s.isAuthenticated, 'isAuthenticated', true)
            .having((s) => s.user?.phone, 'phone', '+85512345678'),
      ],
    );

    blocTest<AuthenticationBloc, AuthenticationState>(
      'surfaces the server’s message on a wrong password',
      setUp: () => api.rejectLogin = true,
      build: buildBloc,
      wait: const Duration(milliseconds: 100),
      act: (bloc) => bloc.add(
        const AuthenticationSignInRequested(
          countryCode: '+855',
          phone: '97573235',
          password: 'wrong',
        ),
      ),
      expect: () => [
        const AuthenticationState(status: AuthenticationStatus.loading),
        const AuthenticationState(
          status: AuthenticationStatus.unauthenticated,
          errorMessage: 'Invalid phone or password',
        ),
      ],
    );
  });

  blocTest<AuthenticationBloc, AuthenticationState>(
    'sign up authenticates the new account',
    build: buildBloc,
    wait: const Duration(milliseconds: 100),
    act: (bloc) => bloc.add(
      const AuthenticationSignUpRequested(
        countryCode: '+855',
        phone: '97573235',
        password: 'Passw0rd!23',
        name: 'KOUY dev',
      ),
    ),
    expect: () => [
      const AuthenticationState(status: AuthenticationStatus.loading),
      isA<AuthenticationState>().having(
        (s) => s.isAuthenticated,
        'isAuthenticated',
        true,
      ),
    ],
    verify: (_) => expect(api.called('/auth/register'), isTrue),
  );

  blocTest<AuthenticationBloc, AuthenticationState>(
    'sign out clears the session and the user',
    setUp: () => tokens.saveTokens(
      accessToken: FakeAuthApi.accessToken,
      refreshToken: FakeAuthApi.refreshToken,
    ),
    build: buildBloc,
    seed: () => const AuthenticationState(
      status: AuthenticationStatus.authenticated,
    ),
    wait: const Duration(milliseconds: 100),
    act: (bloc) => bloc.add(const AuthenticationSignOutRequested()),
    expect: () => [
      const AuthenticationState(status: AuthenticationStatus.unauthenticated),
    ],
    verify: (_) async {
      expect(api.called('/auth/logout'), isTrue);
      expect(await tokens.readRefreshToken(), isNull);
    },
  );

  blocTest<AuthenticationBloc, AuthenticationState>(
    'dismissing an error clears the message and nothing else',
    build: buildBloc,
    seed: () => const AuthenticationState(
      status: AuthenticationStatus.unauthenticated,
      errorMessage: 'Invalid phone or password',
    ),
    act: (bloc) => bloc.add(const AuthenticationErrorDismissed()),
    expect: () => [
      const AuthenticationState(status: AuthenticationStatus.unauthenticated),
    ],
  );
}
