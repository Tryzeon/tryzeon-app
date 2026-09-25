import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/auth/data/datasources/auth_local_datasource.dart';
import 'package:tryzeon/feature/auth/data/datasources/auth_remote_datasource.dart';
import 'package:tryzeon/feature/auth/domain/entities/login_provider.dart';
import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:tryzeon/feature/auth/domain/repositories/auth_repository.dart';
import 'package:typed_result/typed_result.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required final AuthRemoteDataSource remoteDataSource,
    required final AuthLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  @override
  Future<Result<void, Failure>> signInWithProvider({
    required final LoginProvider provider,
    required final UserType userType,
  }) async {
    try {
      // Store login type preference before auth state changes fire.
      await _localDataSource.setLastLoginType(userType.value);

      switch (provider) {
        case LoginProvider.apple:
          if (Platform.isIOS) {
            await _remoteDataSource.signInWithAppleNative();
          } else {
            await _remoteDataSource.signInWithOAuthProvider(OAuthProvider.apple);
          }
        case LoginProvider.google:
          await _remoteDataSource.signInWithGoogleNative();
        case LoginProvider.line:
          await _remoteDataSource.signInWithLineNative();
      }

      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('${provider.name} login failed', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> signOut() async {
    try {
      await _remoteDataSource.signOut();
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Supabase server-side sign-out failed; local session already cleared',
        e,
        stackTrace,
      );
    }
    await _signOutProviderSdks();
    return const Ok(null);
  }

  @override
  Future<Result<UserType?, Failure>> getLastLoginType() async {
    try {
      final typeString = await _localDataSource.getLastLoginType();
      if (typeString == null) return const Ok(null);

      final userType = UserType.tryFromString(typeString) ?? UserType.personal;

      return Ok(userType);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get login type', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> setLastLoginType(final UserType userType) async {
    try {
      await _localDataSource.setLastLoginType(userType.value);
      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save login type', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> sendEmailOtp({
    required final String email,
    required final UserType userType,
  }) async {
    try {
      await _remoteDataSource.sendEmailOTP(email);
      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to send email OTP', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> verifyEmailOtp({
    required final String email,
    required final String token,
    required final UserType userType,
  }) async {
    try {
      await _localDataSource.setLastLoginType(userType.value);

      await _remoteDataSource.verifyEmailOTP(email: email, token: token);

      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Email OTP verification failed', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> deleteAccount() async {
    try {
      await _remoteDataSource.deleteAccount();
      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Account deletion failed on server', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  /// Ends the sessions the provider SDKs keep outside Supabase. Without this
  /// the next sign-in silently reuses the same account and the user can never
  /// switch. Which provider was used isn't recorded, so both run and the one
  /// that wasn't used simply fails or no-ops. Apple has no logout API.
  Future<void> _signOutProviderSdks() async {
    try {
      await _remoteDataSource.signOutGoogle();
    } catch (e, stackTrace) {
      AppLogger.error('Google sign-out failed (ignored)', e, stackTrace);
    }

    try {
      await _remoteDataSource.signOutLine();
    } catch (e, stackTrace) {
      AppLogger.error('LINE sign-out failed (ignored)', e, stackTrace);
    }
  }
}
