import 'package:dio/dio.dart';
import 'package:flutter_piggypal_app/core/di/injection_container.dart';
import 'package:flutter_piggypal_app/core/network/dio_client.dart';
import 'package:flutter_piggypal_app/features/authentication/data/datasources/auth_session_refresher.dart';
import 'package:flutter_piggypal_app/features/authentication/data/datasources/auth_token_store.dart';
import 'package:flutter_piggypal_app/features/authentication/data/datasources/authentication_remote_data_source.dart';
import 'package:flutter_piggypal_app/features/authentication/data/repositories/authentication_repository_impl.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/confirm_phone_verification.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/delete_account.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/get_current_user.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/request_password_reset.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/request_phone_verification.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/request_registration_code.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/reset_password.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/restore_account.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/sign_in.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/sign_out.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/sign_up.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/update_profile_photo.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/verify_password_reset_code.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/usecases/verify_registration_code.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/bloc/password_reset_bloc.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/bloc/phone_verification_bloc.dart';
import 'package:flutter_piggypal_app/features/authentication/presentation/bloc/registration_verification_bloc.dart';

/// Wires authentication into the service locator.
///
/// Registers the shared [Dio] too: it is the auth interceptor that makes it
/// app-wide, and that interceptor reads this feature's token store. Later
/// features can take `sl<Dio>()` and get authenticated requests for free.
///
/// [tokenStore] and [dio] are for tests — an in-memory store and a Dio with a
/// stubbed adapter, so widget tests neither touch the keychain nor a server.
void initAuthentication({AuthTokenStore? tokenStore, Dio? dio}) {
  sl
    ..registerLazySingleton<AuthTokenStore>(
      () => tokenStore ?? SecureAuthTokenStore(),
    )
    ..registerLazySingleton<Dio>(
      () => buildDio(
        readAccessToken: sl<AuthTokenStore>().readAccessToken,
        // Resolved lazily, and it has to be: the refresher needs this very
        // Dio to make its own call. By the time a 401 comes back, both exist.
        refreshSession: (usedAccessToken) => sl<AuthSessionRefresher>().refresh(
          usedAccessToken: usedAccessToken,
        ),
        dio: dio,
      ),
    )
    // Bloc — one per provider. The app provides it once, above the router.
    ..registerFactory(
      () => AuthenticationBloc(
        signIn: sl(),
        signUp: sl(),
        signOut: sl(),
        getCurrentUser: sl(),
        updateProfilePhoto: sl(),
        deleteAccount: sl(),
        restoreAccount: sl(),
        repository: sl(),
      ),
    )
    // One per screen: the two verification steps each drive their own, and
    // neither outlives the screen that made it.
    ..registerFactory(
      () => PhoneVerificationBloc(
        requestPhoneVerification: sl(),
        confirmPhoneVerification: sl(),
      ),
    )
    // One per sign-up screen: the two pre-registration calls belong to the
    // flow on that one screen, and nothing outside it has a use for the proof
    // they produce.
    ..registerFactory(
      () => RegistrationVerificationBloc(
        requestRegistrationCode: sl(),
        verifyRegistrationCode: sl(),
      ),
    )
    // Likewise one per screen, and here that matters more: the three reset
    // steps are three routes, so there is no single tree for one instance to
    // sit above. What has to survive between them travels through the
    // navigation — see PasswordResetBloc.
    ..registerFactory(
      () => PasswordResetBloc(
        requestPasswordReset: sl(),
        verifyPasswordResetCode: sl(),
        resetPassword: sl(),
      ),
    )
    // Use cases.
    ..registerLazySingleton(() => SignIn(sl()))
    ..registerLazySingleton(() => SignUp(sl()))
    ..registerLazySingleton(() => SignOut(sl()))
    ..registerLazySingleton(() => GetCurrentUser(sl()))
    ..registerLazySingleton(() => UpdateProfilePhoto(sl()))
    ..registerLazySingleton(() => DeleteAccount(sl()))
    ..registerLazySingleton(() => RestoreAccount(sl()))
    ..registerLazySingleton(() => RequestPhoneVerification(sl()))
    ..registerLazySingleton(() => RequestRegistrationCode(sl()))
    ..registerLazySingleton(() => VerifyRegistrationCode(sl()))
    ..registerLazySingleton(() => ConfirmPhoneVerification(sl()))
    ..registerLazySingleton(() => RequestPasswordReset(sl()))
    ..registerLazySingleton(() => VerifyPasswordResetCode(sl()))
    ..registerLazySingleton(() => ResetPassword(sl()))
    // Repository.
    ..registerLazySingleton<AuthenticationRepository>(
      () => AuthenticationRepositoryImpl(sl(), sl(), sl()),
    )
    // Data sources.
    ..registerLazySingleton<AuthenticationRemoteDataSource>(
      () => AuthenticationRemoteDataSourceImpl(sl()),
    )
    // Token rotation. A singleton on purpose: its single-flight guard is what
    // stops two concurrent 401s from spending the refresh token twice, and
    // that only works if everyone shares one instance.
    ..registerLazySingleton<AuthSessionRefresher>(
      () => AuthSessionRefresher(sl(), sl()),
    );
}
