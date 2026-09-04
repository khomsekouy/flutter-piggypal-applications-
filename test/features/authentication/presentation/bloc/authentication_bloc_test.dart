import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_piggypal_app/core/network/dio_client.dart';
import 'package:flutter_piggypal_app/features/authentication/data/datasources/auth_session_refresher.dart';
import 'package:flutter_piggypal_app/features/authentication/data/datasources/auth_token_store.dart';
import 'package:flutter_piggypal_app/features/authentication/data/datasources/authentication_remote_data_source.dart';
import 'package:flutter_piggypal_app/features/authentication/data/repositories/authentication_repository_impl.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/delete_account.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/get_current_user.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/restore_account.dart';
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
    deleteAccount: DeleteAccount(repository),
    restoreAccount: RestoreAccount(repository),
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
        // The login body alone: five fields, so the profile-only ones are
        // still at their defaults.
        isA<AuthenticationState>()
            .having((s) => s.isAuthenticated, 'isAuthenticated', true)
            .having((s) => s.user?.phone, 'phone', '+85512345678')
            .having((s) => s.user?.createdAt, 'createdAt', isNull),
        // Then `GET /users/me` fills in the rest, which is the whole point:
        // without it the account screen renders a join date nobody has.
        isA<AuthenticationState>()
            .having((s) => s.isAuthenticated, 'isAuthenticated', true)
            .having((s) => s.user?.currency, 'currency', 'USD')
            .having((s) => s.user?.status, 'status', 'active')
            .having((s) => s.user?.phoneVerified, 'phoneVerified', true)
            .having(
              (s) => s.user?.createdAt,
              'createdAt',
              DateTime.utc(2026, 1, 15, 8).toLocal(),
            ),
      ],
      verify: (_) => expect(api.called('/users/me'), isTrue),
    );

    blocTest<AuthenticationBloc, AuthenticationState>(
      'stays signed in when the profile read fails',
      setUp: () => api.rejectCurrentUser = true,
      build: buildBloc,
      wait: const Duration(milliseconds: 100),
      act: (bloc) => bloc.add(
        const AuthenticationSignInRequested(
          countryCode: '+855',
          phone: '97573235',
          password: 'Passw0rd!23',
        ),
      ),
      // One state, not two: the tokens are stored and the account is signed
      // in, so a profile that will not load costs the user some fields, never
      // the session.
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
      // Registering reads the profile for the same reason signing in does.
      isA<AuthenticationState>().having(
        (s) => s.user?.currency,
        'currency',
        'USD',
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

  group('delete account', () {
    Future<void> signIn(AuthenticationBloc bloc) async {
      bloc.add(
        const AuthenticationSignInRequested(
          countryCode: '+855',
          phone: '97573235',
          password: 'supersecret',
        ),
      );
      await bloc.stream.firstWhere((s) => s.isAuthenticated);
    }

    blocTest<AuthenticationBloc, AuthenticationState>(
      'signs out and carries the recovery date to the next screen',
      build: buildBloc,
      wait: const Duration(milliseconds: 100),
      act: (bloc) async {
        await signIn(bloc);
        bloc.add(
          const AuthenticationDeleteAccountRequested(password: 'supersecret'),
        );
      },
      // The sign-in emissions are setup, not the subject.
      expect: () => containsAllInOrder([
        isA<AuthenticationState>()
            .having(
              (s) => s.status,
              'status',
              AuthenticationStatus.unauthenticated,
            )
            .having((s) => s.user, 'user', isNull)
            // The date is the whole reason the notice exists: it is the one
            // thing the user needs, and the screen that can show it has not
            // been built yet when this is emitted.
            .having((s) => s.notice, 'notice', contains('October 2, 2026')),
      ]),
      verify: (_) async {
        expect(api.accountDeleted, isTrue);
        expect(await tokens.readAccessToken(), isNull);
        expect(await tokens.readRefreshToken(), isNull);
      },
    );

    blocTest<AuthenticationBloc, AuthenticationState>(
      'a wrong password leaves the user signed in, with the reason',
      build: buildBloc,
      wait: const Duration(milliseconds: 100),
      act: (bloc) async {
        await signIn(bloc);
        bloc.add(
          const AuthenticationDeleteAccountRequested(password: 'not-it'),
        );
      },
      expect: () => containsAllInOrder([
        isA<AuthenticationState>()
            .having(
              (s) => s.status,
              'status',
              AuthenticationStatus.authenticated,
            )
            .having((s) => s.errorMessage, 'error', 'Password is incorrect')
            .having((s) => s.notice, 'notice', isNull),
      ]),
      verify: (_) async {
        expect(api.accountDeleted, isFalse);
        // Signing someone out over a typo, on this screen of all screens,
        // would read as the deletion having half-happened.
        expect(await tokens.readAccessToken(), isNotNull);
      },
    );
  });

  blocTest<AuthenticationBloc, AuthenticationState>(
    'dismissing an error keeps the notice, which has its own event',
    build: buildBloc,
    seed: () => const AuthenticationState(
      status: AuthenticationStatus.unauthenticated,
      errorMessage: 'Invalid phone or password',
      notice: 'Your account is scheduled for deletion.',
    ),
    act: (bloc) => bloc
      ..add(const AuthenticationErrorDismissed())
      ..add(const AuthenticationNoticeDismissed()),
    // The sign-in screen shows both, and a failed sign-in there must not wipe
    // the deletion notice that sent the user to it.
    expect: () => const [
      AuthenticationState(
        status: AuthenticationStatus.unauthenticated,
        notice: 'Your account is scheduled for deletion.',
      ),
      AuthenticationState(status: AuthenticationStatus.unauthenticated),
    ],
  );

  group('restore account', () {
    Future<void> deleteAccount(AuthenticationBloc bloc) async {
      bloc.add(
        const AuthenticationSignInRequested(
          countryCode: '+855',
          phone: '97573235',
          password: 'supersecret',
        ),
      );
      await bloc.stream.firstWhere((s) => s.isAuthenticated);
      bloc.add(
        const AuthenticationDeleteAccountRequested(password: 'supersecret'),
      );
      await bloc.stream.firstWhere((s) => s.notice != null);
    }

    blocTest<AuthenticationBloc, AuthenticationState>(
      'brings the account back and signs straight in',
      build: buildBloc,
      wait: const Duration(milliseconds: 100),
      act: (bloc) async {
        await deleteAccount(bloc);
        bloc.add(
          const AuthenticationAccountRestoreRequested(
            countryCode: '+855',
            phone: '97573235',
            password: 'supersecret',
          ),
        );
      },
      // Signed in, not merely undeleted: the endpoint answers with a session,
      // so there is no second trip through the login screen.
      expect: () => containsAllInOrder([
        isA<AuthenticationState>()
            .having((s) => s.isAuthenticated, 'authenticated', isTrue)
            .having((s) => s.user?.phone, 'user', '+85512345678'),
      ]),
      verify: (_) async {
        expect(api.accountDeleted, isFalse);
        expect(await tokens.readAccessToken(), isNotNull);
        // No session to present, so none is sent — and refreshing the one the
        // deletion revoked would be read server-side as a leak.
        expect(
          api.requestTo('/auth/restore-account')!.isAuthenticated,
          isFalse,
        );
      },
    );

    blocTest<AuthenticationBloc, AuthenticationState>(
      'a lapsed window stays unauthenticated and says why',
      build: buildBloc,
      wait: const Duration(milliseconds: 100),
      act: (bloc) async {
        await deleteAccount(bloc);
        api.recoveryWindowClosed = true;
        bloc.add(
          const AuthenticationAccountRestoreRequested(
            countryCode: '+855',
            phone: '97573235',
            password: 'supersecret',
          ),
        );
      },
      expect: () => containsAllInOrder([
        isA<AuthenticationState>()
            .having(
              (s) => s.status,
              'status',
              AuthenticationStatus.unauthenticated,
            )
            .having(
              (s) => s.errorMessage,
              'error',
              'The recovery window for this account has passed',
            ),
      ]),
    );
  });
}
