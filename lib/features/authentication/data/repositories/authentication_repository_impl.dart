import 'dart:typed_data';

import 'package:flutter_piggypal_app/core/error/exceptions.dart';
import 'package:flutter_piggypal_app/core/error/failure_mapper.dart';
import 'package:flutter_piggypal_app/core/error/failures.dart';
import 'package:flutter_piggypal_app/core/utils/typedefs.dart';
import 'package:flutter_piggypal_app/features/authentication/data/datasources/auth_session_refresher.dart';
import 'package:flutter_piggypal_app/features/authentication/data/datasources/auth_token_store.dart';
import 'package:flutter_piggypal_app/features/authentication/data/datasources/authentication_remote_data_source.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/entities/auth_session.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/entities/auth_user.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/entities/phone_verification_request.dart';
import 'package:flutter_piggypal_app/features/authentication/domain/repositories/authentication_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Runs the auth calls and owns the tokens they produce.
///
/// Storing the session here rather than in the bloc is what makes every other
/// request authenticated for free: the dio interceptor reads the same store.
class AuthenticationRepositoryImpl implements AuthenticationRepository {
  const AuthenticationRepositoryImpl(this._remote, this._tokens, this._session);

  final AuthenticationRemoteDataSource _remote;
  final AuthTokenStore _tokens;

  /// Owns token rotation. The repository never calls it directly — the dio
  /// interceptor does, on any 401 — but it is where the "session is over"
  /// signal comes from.
  final AuthSessionRefresher _session;

  @override
  Stream<void> get sessionExpired => _session.sessionExpired;

  @override
  ResultFuture<AuthSession> signIn({
    required String countryCode,
    required String phone,
    required String password,
  }) async {
    try {
      final session = await _remote.login(
        countryCode: countryCode,
        phone: phone,
        password: password,
        deviceId: await _tokens.deviceId(),
        deviceName: _tokens.deviceName,
      );
      await _tokens.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      return Right(session);
    } on Exception catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  ResultFuture<AuthSession> signUp({
    required String countryCode,
    required String phone,
    required String password,
    String? email,
    String? name,
    Uint8List? avatar,
    String? avatarFileName,
  }) async {
    try {
      final session = await _remote.register(
        countryCode: countryCode,
        phone: phone,
        password: password,
        email: email,
        name: name,
        avatar: avatar,
        avatarFileName: avatarFileName,
        deviceId: await _tokens.deviceId(),
        deviceName: _tokens.deviceName,
      );
      // Sign-up answers with a session, so a new account is signed in already
      // — no second round trip to /auth/login.
      await _tokens.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      return Right(session);
    } on Exception catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  ResultVoid signOut() async {
    final refreshToken = await _tokens.readRefreshToken();

    // Best effort: the server call revokes the session so the refresh token
    // cannot mint new access tokens. If it fails — offline, token already
    // revoked — the local tokens still go, because a sign-out that a flaky
    // connection can refuse is not a sign-out.
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _remote.logout(refreshToken: refreshToken);
      } on Exception {
        // Deliberately swallowed; see above.
      }
    }

    try {
      await _tokens.clear();
      return const Right(null);
    } on SecureStorageException catch (e) {
      // This one does matter: tokens we failed to erase are still on the
      // device and still work.
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  ResultFuture<AuthUser> getCurrentUser() async {
    try {
      return Right(await _remote.getCurrentUser());
    } on UnauthorizedException catch (e) {
      // Reached only after a refresh was tried and failed — the interceptor
      // retries first. Drop the tokens so the app stops presenting a
      // credential the server has already rejected.
      await _tokens.clear();
      return Left(AuthFailure(e.message));
    } on Exception catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  ResultFuture<AuthUser> updateProfilePhoto({
    required Uint8List avatar,
    String? avatarFileName,
  }) async {
    try {
      return Right(
        await _remote.updateProfilePhoto(
          avatar: avatar,
          avatarFileName: avatarFileName,
        ),
      );
    } on Exception catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  ResultFuture<PhoneVerificationRequest> requestPhoneVerification() async {
    try {
      return Right(await _remote.requestPhoneVerification());
    } on Exception catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  ResultVoid confirmPhoneVerification({required String code}) async {
    try {
      await _remote.confirmPhoneVerification(code: code);
      return const Right(null);
    } on Exception catch (e) {
      return Left(failureFromException(e));
    }
  }

  @override
  Future<bool> hasSession() async {
    final token = await _tokens.readAccessToken();
    return token != null && token.isNotEmpty;
  }
}
