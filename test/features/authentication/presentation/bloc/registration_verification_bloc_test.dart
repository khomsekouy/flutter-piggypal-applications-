import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_piggypal_app/core/network/dio_client.dart';
import 'package:flutter_piggypal_app/features/authentication/data/datasources/auth_session_refresher.dart';
import 'package:flutter_piggypal_app/features/authentication/data/datasources/auth_token_store.dart';
import 'package:flutter_piggypal_app/features/authentication/data/datasources/authentication_remote_data_source.dart';
import 'package:flutter_piggypal_app/features/authentication/data/repositories/authentication_repository_impl.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/request_registration_code.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/verify_registration_code.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/bloc/registration_verification_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/helpers.dart';

void main() {
  late FakeAuthApi api;
  late InMemoryAuthTokenStore tokens;
  late AuthSessionRefresher refresher;
  late AuthenticationRepository repository;

  RegistrationVerificationBloc buildBloc() => RegistrationVerificationBloc(
    requestRegistrationCode: RequestRegistrationCode(repository),
    verifyRegistrationCode: VerifyRegistrationCode(repository),
  );

  /// Puts the bloc where step two starts: a code has been issued for the
  /// number, which is what step one does.
  Future<void> issueCode(RegistrationVerificationBloc bloc) async {
    bloc.add(
      const RegistrationCodeRequested(countryCode: '+855', phone: '12345678'),
    );
    await bloc.stream.firstWhere(
      (state) => state.status == RegistrationVerificationStatus.codeSent,
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

  group('register/request-otp', () {
    blocTest<RegistrationVerificationBloc, RegistrationVerificationState>(
      'asks the server for a code and carries the mocked one back',
      build: buildBloc,
      wait: const Duration(milliseconds: 100),
      act: (bloc) => bloc.add(
        const RegistrationCodeRequested(countryCode: '+855', phone: '12345678'),
      ),
      expect: () => [
        const RegistrationVerificationState(
          status: RegistrationVerificationStatus.sendingCode,
        ),
        RegistrationVerificationState(
          status: RegistrationVerificationStatus.codeSent,
          phone: '12345678',
          devCode: api.mockCode,
        ),
      ],
      verify: (_) {
        // Split, the way the API wants it: the dial code and the national
        // number apart, never one joined string.
        expect(api.requestTo('/auth/register/request-otp')?.fields, {
          'countryCode': '+855',
          'phone': '12345678',
        });
        // Unguarded, and it must go out that way: there is no account yet, so
        // there is no token to present.
        expect(
          api.requestTo('/auth/register/request-otp')?.isAuthenticated,
          isFalse,
        );
      },
    );

    blocTest<RegistrationVerificationBloc, RegistrationVerificationState>(
      'says plainly when the number already has an account',
      build: buildBloc,
      setUp: () => api.registeredPhone = '+85512345678',
      wait: const Duration(milliseconds: 100),
      act: (bloc) => bloc.add(
        const RegistrationCodeRequested(countryCode: '+855', phone: '12345678'),
      ),
      expect: () => [
        const RegistrationVerificationState(
          status: RegistrationVerificationStatus.sendingCode,
        ),
        // Back to where the user was standing, with the complaint marked as
        // one about the number rather than the six digits — no code was sent,
        // so nothing on a code screen could act on it.
        const RegistrationVerificationState(
          errorMessage: 'Phone is already registered',
          numberRejected: true,
        ),
      ],
    );

    blocTest<RegistrationVerificationBloc, RegistrationVerificationState>(
      'a refused resend leaves the code that is already out there standing',
      build: buildBloc,
      setUp: () => api.registeredPhone = null,
      wait: const Duration(milliseconds: 100),
      act: (bloc) async {
        await issueCode(bloc);
        api.throttleRegistrationCodes = true;
        bloc.add(
          const RegistrationCodeRequested(
            countryCode: '+855',
            phone: '12345678',
          ),
        );
      },
      skip: 2,
      expect: () => [
        RegistrationVerificationState(
          status: RegistrationVerificationStatus.sendingCode,
          phone: '12345678',
          devCode: api.mockCode,
        ),
        // Still `codeSent`: the code in their messages did not stop working
        // because the server refused to send a second one.
        RegistrationVerificationState(
          status: RegistrationVerificationStatus.codeSent,
          phone: '12345678',
          devCode: api.mockCode,
          errorMessage:
              'Too many attempts. Please wait a few minutes and try again.',
        ),
      ],
    );
  });

  group('register/verify-otp', () {
    blocTest<RegistrationVerificationBloc, RegistrationVerificationState>(
      'trades a correct code for the proof register spends',
      build: buildBloc,
      wait: const Duration(milliseconds: 100),
      act: (bloc) async {
        await issueCode(bloc);
        bloc.add(
          RegistrationCodeSubmitted(
            countryCode: '+855',
            phone: '12345678',
            code: api.mockCode,
          ),
        );
      },
      skip: 2,
      expect: () => [
        RegistrationVerificationState(
          status: RegistrationVerificationStatus.verifyingCode,
          phone: '12345678',
          devCode: api.mockCode,
        ),
        RegistrationVerificationState(
          status: RegistrationVerificationStatus.verified,
          phone: '12345678',
          token: api.verificationToken,
          devCode: api.mockCode,
        ),
      ],
      verify: (bloc) {
        expect(bloc.state.provesNumber('12345678'), isTrue);
        // The proof names the number it was issued for, so an edited digit
        // makes it worth nothing — which is what the screen reads to decide
        // whether another code is needed.
        expect(bloc.state.provesNumber('87654321'), isFalse);
        // No account yet: that is the request after this one.
        expect(api.called('/auth/register'), isFalse);
      },
    );

    blocTest<RegistrationVerificationBloc, RegistrationVerificationState>(
      'a wrong code is the code, not the session',
      build: buildBloc,
      wait: const Duration(milliseconds: 100),
      act: (bloc) async {
        await issueCode(bloc);
        bloc.add(
          const RegistrationCodeSubmitted(
            countryCode: '+855',
            phone: '12345678',
            code: '000000',
          ),
        );
      },
      skip: 2,
      expect: () => [
        RegistrationVerificationState(
          status: RegistrationVerificationStatus.verifyingCode,
          phone: '12345678',
          devCode: api.mockCode,
        ),
        // Back to `codeSent`, because a code is still out there — and marked
        // as the digits being wrong, which is what paints the boxes red
        // rather than showing a passing message.
        RegistrationVerificationState(
          status: RegistrationVerificationStatus.codeSent,
          phone: '12345678',
          devCode: api.mockCode,
          errorMessage: 'Verification code is invalid or expired',
          codeRejected: true,
        ),
      ],
    );

    blocTest<RegistrationVerificationBloc, RegistrationVerificationState>(
      'throwing the proof away puts the flow back to its first step',
      build: buildBloc,
      wait: const Duration(milliseconds: 100),
      act: (bloc) async {
        await issueCode(bloc);
        bloc.add(
          RegistrationCodeSubmitted(
            countryCode: '+855',
            phone: '12345678',
            code: api.mockCode,
          ),
        );
        await bloc.stream.firstWhere((state) => state.isVerified);
        bloc.add(const RegistrationVerificationInvalidated());
      },
      skip: 4,
      expect: () => [const RegistrationVerificationState()],
      verify: (bloc) =>
          expect(bloc.state.provesNumber('12345678'), isFalse),
    );
  });
}
