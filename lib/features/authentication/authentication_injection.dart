import 'package:dio/dio.dart';
import 'package:flutter_piggypal_app/core/di/injection_container.dart';
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
import 'package:flutter_piggypal_app/features/authentication/presentation/bloc/authentication_bloc.dart';

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
        repository: sl(),
      ),
    )
    // Use cases.
    ..registerLazySingleton(() => SignIn(sl()))
    ..registerLazySingleton(() => SignUp(sl()))
    ..registerLazySingleton(() => SignOut(sl()))
    ..registerLazySingleton(() => GetCurrentUser(sl()))
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
