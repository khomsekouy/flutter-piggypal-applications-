import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_piggypal_app/core/network/dio_client.dart';
import 'package:flutter_piggypal_app/features/authentication/data/datasources/auth_session_refresher.dart';
import 'package:flutter_piggypal_app/features/authentication/data/datasources/auth_token_store.dart';
import 'package:flutter_piggypal_app/features/authentication/data/datasources/authentication_remote_data_source.dart';
import 'package:flutter_piggypal_app/features/authentication/data/repositories/authentication_repository_impl.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/request_password_reset.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/reset_password.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/verify_password_reset_code.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/bloc/password_reset_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/helpers.dart';

void main() {
  late FakeAuthApi api;
  late InMemoryAuthTokenStore tokens;
  late AuthSessionRefresher refresher;
  late AuthenticationRepository repository;

  PasswordResetBloc buildBloc() => PasswordResetBloc(
    requestPasswordReset: RequestPasswordReset(repository),
    verifyPasswordResetCode: VerifyPasswordResetCode(repository),
    resetPassword: ResetPassword(repository),
  );

  /// Puts the bloc where step two starts: a code has been issued for the
  /// number, which is what step one does.
  Future<void> issueCode(PasswordResetBloc bloc) async {
    bloc.add(
      const PasswordResetCodeRequested(countryCode: '+855', phone: '12345678'),
    );
    await bloc.stream.firstWhere(
      (state) => state.status == PasswordResetStatus.codeSent,
    );
  }

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

  group('forgot-password', () {
    blocTest<PasswordResetBloc, PasswordResetState>(
      'asks the server for a code and carries the mocked one back',
      build: buildBloc,
      wait: const Duration(milliseconds: 100),
      act: (bloc) => bloc.add(
        const PasswordResetCodeRequested(
          countryCode: '+855',
          phone: '12345678',
        ),
      ),
      expect: () => [
        const PasswordResetState(status: PasswordResetStatus.sendingCode),
        PasswordResetState(
          status: PasswordResetStatus.codeSent,
          devCode: api.mockCode,
        ),
      ],
      verify: (_) {
        // Split, the way the API wants it: the dial code and the national
        // number apart, never one joined string.
        expect(api.requestTo('/auth/forgot-password')?.fields, {
          'countryCode': '+855',
          'phone': '12345678',
        });
        // Unguarded, and it must go out that way: the caller has no session.
        expect(
          api.requestTo('/auth/forgot-password')?.isAuthenticated,
          isFalse,
        );
      },
    );

    blocTest<PasswordResetBloc, PasswordResetState>(
      'succeeds for a number with no account, and says nothing about it',
      build: buildBloc,
      wait: const Duration(milliseconds: 100),
      act: (bloc) => bloc.add(
        const PasswordResetCodeRequested(
          countryCode: '+855',
          phone: '99999999',
        ),
      ),
      // Identical to the registered case but for `devCode`, which a server
      // with real SMS would not send either. Reporting the difference is
      // exactly what the endpoint is shaped to prevent.
      expect: () => [
        const PasswordResetState(status: PasswordResetStatus.sendingCode),
        const PasswordResetState(status: PasswordResetStatus.codeSent),
      ],
      verify: (_) => expect(api.resetCodeRequests, 0),
    );

    blocTest<PasswordResetBloc, PasswordResetState>(
      'a throttled send stays put and names the wait',
      build: buildBloc,
      wait: const Duration(milliseconds: 100),
      setUp: () => api.throttleResetRequests = true,
      act: (bloc) => bloc.add(
        const PasswordResetCodeRequested(
          countryCode: '+855',
          phone: '12345678',
        ),
      ),
      expect: () => [
        const PasswordResetState(status: PasswordResetStatus.sendingCode),
        // Back to `initial`, so the screen does not move on to a code that
        // was never sent. The framework's own `ThrottlerException` wording is
        // replaced before it ever reaches a snackbar.
        const PasswordResetState(
          errorMessage:
              'Too many attempts. Please wait a few minutes and try again.',
        ),
      ],
    );
  });

  group('verify-otp', () {
    blocTest<PasswordResetBloc, PasswordResetState>(
      'a correct code comes back with the reset token',
      build: buildBloc,
      wait: const Duration(milliseconds: 100),
      act: (bloc) async {
        await issueCode(bloc);
        bloc.add(
          PasswordResetCodeSubmitted(
            countryCode: '+855',
            phone: '12345678',
            code: api.mockCode,
          ),
        );
      },
      skip: 2,
      expect: () => [
        PasswordResetState(
          status: PasswordResetStatus.verifyingCode,
          devCode: api.mockCode,
        ),
        PasswordResetState(
          status: PasswordResetStatus.codeVerified,
          devCode: api.mockCode,
          resetToken: api.resetToken,
        ),
      ],
      verify: (_) => expect(api.requestTo('/auth/verify-otp')?.fields, {
        'countryCode': '+855',
        'phone': '12345678',
        'code': api.mockCode,
      }),
    );

    blocTest<PasswordResetBloc, PasswordResetState>(
      'a wrong code is a rejection, not a dead session',
      build: buildBloc,
      wait: const Duration(milliseconds: 100),
      act: (bloc) async {
        await issueCode(bloc);
        bloc.add(
          const PasswordResetCodeSubmitted(
            countryCode: '+855',
            phone: '12345678',
            code: '000000',
          ),
        );
      },
      skip: 3,
      expect: () => [
        PasswordResetState(
          // Back to `codeSent`: the code in their messages still works, and
          // they have guesses left.
          status: PasswordResetStatus.codeSent,
          devCode: api.mockCode,
          errorMessage: 'Verification code is invalid or expired',
          // The difference between painting the boxes red and telling
          // somebody their session expired — which it cannot have, there
          // being none.
          codeRejected: true,
        ),
      ],
      verify: (_) {
        // No refresh: replaying would spend a second of the five guesses the
        // server allows, and there is no token here to refresh anyway.
        expect(api.called('/auth/refresh'), isFalse);
        expect(api.requestTo('/auth/verify-otp')?.isAuthenticated, isFalse);
      },
    );
  });

  group('reset-password', () {
    blocTest<PasswordResetBloc, PasswordResetState>(
      'sets the new password and revokes every session',
      build: buildBloc,
      wait: const Duration(milliseconds: 100),
      setUp: () => tokens.saveTokens(
        accessToken: FakeAuthApi.accessToken,
        refreshToken: FakeAuthApi.refreshToken,
      ),
      act: (bloc) => bloc.add(
        PasswordResetSubmitted(
          resetToken: api.resetToken,
          newPassword: 'brand-new-secret',
        ),
      ),
      expect: () => [
        const PasswordResetState(status: PasswordResetStatus.updatingPassword),
        const PasswordResetState(status: PasswordResetStatus.passwordUpdated),
      ],
      verify: (_) async {
        expect(api.requestTo('/auth/reset-password')?.fields, {
          'resetToken': 'test-reset-token-0123456789',
          'newPassword': 'brand-new-secret',
        });
        // The password really changed — this is what login checks next.
        expect(api.accountPassword, 'brand-new-secret');
        // And the device's own tokens are gone: the server revoked them, so
        // keeping them would only make the next request a pointless 401.
        expect(await tokens.readAccessToken(), isNull);
        expect(await tokens.readRefreshToken(), isNull);
      },
    );

    blocTest<PasswordResetBloc, PasswordResetState>(
      'an expired token is a rejection to start over, not a lost session',
      build: buildBloc,
      wait: const Duration(milliseconds: 100),
      setUp: () => api.rejectResetToken = true,
      act: (bloc) => bloc.add(
        PasswordResetSubmitted(
          resetToken: api.resetToken,
          newPassword: 'brand-new-secret',
        ),
      ),
      expect: () => [
        const PasswordResetState(status: PasswordResetStatus.updatingPassword),
        const PasswordResetState(
          errorMessage: 'Reset token is invalid or expired',
          // `codeRejected`, so the screen sends them back to the number
          // rather than telling a signed-out user to sign in again.
          codeRejected: true,
        ),
      ],
      verify: (_) => expect(api.accountPassword, 'supersecret'),
    );

    blocTest<PasswordResetBloc, PasswordResetState>(
      'the token is good for one use',
      build: buildBloc,
      wait: const Duration(milliseconds: 100),
      act: (bloc) async {
        final token = api.resetToken;
        bloc.add(
          PasswordResetSubmitted(resetToken: token, newPassword: 'first-pass'),
        );
        await bloc.stream.firstWhere(
          (state) => state.status == PasswordResetStatus.passwordUpdated,
        );
        bloc.add(
          PasswordResetSubmitted(resetToken: token, newPassword: 'second-pass'),
        );
      },
      skip: 3,
      expect: () => [
        const PasswordResetState(
          errorMessage: 'Reset token is invalid or expired',
          codeRejected: true,
        ),
      ],
      verify: (_) => expect(api.accountPassword, 'first-pass'),
    );
  });
}
