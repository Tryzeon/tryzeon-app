import 'dart:io';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/profile/data/datasources/user_profile_local_datasource.dart';
import 'package:tryzeon/feature/personal/profile/data/datasources/user_profile_remote_datasource.dart';
import 'package:tryzeon/feature/personal/profile/data/models/user_profile_model.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
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

  @override
  Future<Result<UserProfile, Failure>> getUserProfile({
    final bool forceRefresh = false,
  }) async {
    // 1. Try Local Cache
    if (!forceRefresh) {
      try {
        final cachedProfile = await _localDataSource.getUserProfile();
        if (cachedProfile != null) return Ok(cachedProfile.toEntity());
      } catch (e, stackTrace) {
        AppLogger.warning(
          'Local cache read failed, falling back to remote',
          e,
          stackTrace,
        );
      }
    }

    // 2. Fetch from API
    try {
      final remoteProfile = await _remoteDataSource.getUserProfile();

      // 3. Update Cache
      try {
        await _localDataSource.saveUserProfile(remoteProfile);
      } catch (e, stackTrace) {
        AppLogger.warning('Failed to save user profile to cache', e, stackTrace);
      }

      return Ok(remoteProfile.toEntity());
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load user profile', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> updateUserProfile({
    required final UserProfile original,
    required final UserProfile target,
    final File? avatarFile,
  }) async {
    try {
      UserProfile finalTarget = target;

      // Handle Avatar Upload
      if (avatarFile != null) {
        final newAvatarPath = await _remoteDataSource.uploadAvatar(avatarFile);
        finalTarget = target.copyWith(avatarPath: newAvatarPath);

        // Optimistic cache update for image
        final bytes = await avatarFile.readAsBytes();
        await _localDataSource.saveAvatar(bytes, newAvatarPath);
      }

      final hasChanges = original != finalTarget;

      if (!hasChanges) {
        return const Ok(null);
      }

      final targetModel = UserProfileModel.fromEntity(finalTarget);

      final updatedProfile = await _remoteDataSource.updateUserProfile(targetModel);

      await _localDataSource.saveUserProfile(updatedProfile);

      // Clean up old avatar if changed
      if (avatarFile != null &&
          original.avatarPath != null &&
          original.avatarPath!.isNotEmpty) {
        // Fire and forget
        _remoteDataSource.deleteAvatar(original.avatarPath!);
        _localDataSource.deleteAvatar(original.avatarPath!);
      }

      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update user profile', e, stackTrace);
      return Err(mapExceptionToFailure(e));
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
