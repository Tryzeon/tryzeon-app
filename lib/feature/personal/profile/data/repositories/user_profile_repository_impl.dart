import 'dart:io';

import 'package:tryzeon/core/data/errors/map_exception_to_failure.dart';
import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/profile/data/datasources/user_profile_local_datasource.dart';
import 'package:tryzeon/feature/personal/profile/data/datasources/user_profile_remote_datasource.dart';
import 'package:tryzeon/feature/personal/profile/data/dtos/update_avatar_request.dart';
import 'package:tryzeon/feature/personal/profile/data/dtos/update_user_profile_request.dart';
import 'package:tryzeon/feature/personal/profile/data/dtos/user_profile_dto.dart';
import 'package:tryzeon/feature/personal/profile/data/mappers/user_profile_mappr.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile_update.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:typed_result/typed_result.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  UserProfileRepositoryImpl({
    required final UserProfileRemoteDataSource remoteDataSource,
    required final UserProfileLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final UserProfileRemoteDataSource _remoteDataSource;
  final UserProfileLocalDataSource _localDataSource;
  static const _mappr = UserProfileMappr();

  @override
  Future<Result<UserProfile, Failure>> getUserProfile({
    final bool forceRefresh = false,
  }) async {
    try {
      // 1. Try Local Cache
      if (!forceRefresh) {
        try {
          final cachedProfile = await _localDataSource.getUserProfile();
          switch (cachedProfile) {
            case CacheHit<UserProfile>(:final data):
              return Ok(data);
            case CacheEmpty<UserProfile>():
            case CacheMiss<UserProfile>():
              break;
          }
        } catch (e, stackTrace) {
          AppLogger.warning(
            'Local cache read failed, falling back to remote',
            e,
            stackTrace,
          );
        }
      }

      // 2. Fetch from API
      final profile = _mappr.convert<UserProfileDto, UserProfile>(
        await _remoteDataSource.getUserProfile(),
      );

      // 3. Update Cache
      try {
        await _localDataSource.saveUserProfile(profile);
      } catch (e, stackTrace) {
        AppLogger.warning(
          'Failed to save user profile to cache',
          e,
          stackTrace,
        );
      }

      return Ok(profile);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load user profile', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> updateUserProfile(
    final UserProfileUpdate update,
  ) async {
    try {
      await _remoteDataSource.updateUserProfile(
        _mappr.convert<UserProfileUpdate, UpdateUserProfileRequest>(update),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update user profile', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }

    await _refreshCachedProfile();
    return const Ok(null);
  }

  @override
  Future<Result<void, Failure>> updateAvatar(final Avatar avatar) async {
    try {
      await _remoteDataSource.updateAvatar(
        _mappr.convert<Avatar, UpdateAvatarRequest>(avatar),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update avatar', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
    await _refreshCachedProfile();
    return const Ok(null);
  }

  Future<void> _refreshCachedProfile() async {
    try {
      await _localDataSource.saveUserProfile(
        _mappr.convert<UserProfileDto, UserProfile>(
          await _remoteDataSource.getUserProfile(),
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.warning(
        'User profile refresh failed, invalidating cache',
        e,
        stackTrace,
      );
      try {
        await _localDataSource.invalidateUserProfile();
      } catch (e, stackTrace) {
        AppLogger.error(
          'Failed to invalidate user profile cache',
          e,
          stackTrace,
        );
      }
    }
  }

  @override
  Future<Result<File, Failure>> getUserAvatar(final String path) async {
    try {
      // 1. Try Local Cache
      final cachedAvatar = await _localDataSource.getAvatar(path);
      if (cachedAvatar != null) {
        return Ok(cachedAvatar);
      }

      // 2. If missing, generate URL and download
      final url = await _remoteDataSource.createSignedUrl(path);
      final downloadedAvatar = await _localDataSource.downloadAvatar(path, url);

      if (downloadedAvatar == null) {
        return const Err(UnknownFailure('無法獲取個人頭像'));
      }

      return Ok(downloadedAvatar);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load profile avatar', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
