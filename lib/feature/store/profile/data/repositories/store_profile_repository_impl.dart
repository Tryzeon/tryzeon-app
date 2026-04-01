import 'dart:io';

import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/store/data/mappers/store_mappr.dart';
import 'package:tryzeon/feature/store/profile/data/datasources/store_profile_local_datasource.dart';
import 'package:tryzeon/feature/store/profile/data/datasources/store_profile_remote_datasource.dart';
import 'package:tryzeon/feature/store/profile/data/models/store_profile_model.dart';
import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart';
import 'package:tryzeon/feature/store/profile/domain/repositories/store_profile_repository.dart';
import 'package:typed_result/typed_result.dart';

class StoreProfileRepositoryImpl implements StoreProfileRepository {
  StoreProfileRepositoryImpl({
    required final StoreProfileRemoteDataSource remoteDataSource,
    required final StoreProfileLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final StoreProfileRemoteDataSource _remoteDataSource;
  final StoreProfileLocalDataSource _localDataSource;
  static const _mappr = StoreMappr();

  @override
  Future<Result<StoreProfile?, Failure>> getStoreProfile({
    final bool forceRefresh = false,
  }) async {
    try {
      // 1. Try Local Cache
      if (!forceRefresh) {
        try {
          final cachedProfile = await _localDataSource.getStoreProfile();
          switch (cachedProfile) {
            case CacheHit<StoreProfileModel>(:final data):
              final profile = _mappr.convert<StoreProfileModel, StoreProfile>(data);
              return Ok(profile);
            case CacheEmpty<StoreProfileModel>():
              return const Ok(null);
            case CacheMiss<StoreProfileModel>():
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
      final remoteProfile = await _remoteDataSource.getStoreProfile();
      if (remoteProfile == null) {
        try {
          await _localDataSource.markStoreProfileAbsent();
        } catch (e, stackTrace) {
          AppLogger.warning('Failed to mark store profile cache empty', e, stackTrace);
        }
        return const Ok(null);
      }

      // 3. Update Cache
      try {
        await _localDataSource.saveStoreProfile(remoteProfile);
      } catch (e, stackTrace) {
        AppLogger.warning('Failed to save store profile to cache', e, stackTrace);
      }

      final profile = _mappr.convert<StoreProfileModel, StoreProfile>(remoteProfile);
      return Ok(profile);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load store profile', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> updateStoreProfile({
    required final StoreProfile original,
    required final StoreProfile target,
    final File? logoFile,
  }) async {
    try {
      StoreProfile finalTarget = target;

      // Handle Logo Upload
      if (logoFile != null) {
        final newLogoPath = await _remoteDataSource.uploadLogo(
          storeId: target.id,
          image: logoFile,
        );
        finalTarget = target.copyWith(logoPath: newLogoPath);
      }

      final hasChanges = original != finalTarget;

      if (!hasChanges) {
        return const Ok(null);
      }

      final targetModel = _mappr.convert<StoreProfile, StoreProfileModel>(finalTarget);
      final updatedProfile = await _remoteDataSource.updateStoreProfile(targetModel);

      await _localDataSource.saveStoreProfile(updatedProfile);

      // Clean up old logo if changed
      if (logoFile != null &&
          original.logoPath != null &&
          original.logoPath!.isNotEmpty) {
        // Fire and forget
        _remoteDataSource.deleteLogo(original.logoPath!);
        // We no longer manually delete from local cache as we use network image cache
      }

      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update store profile', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
