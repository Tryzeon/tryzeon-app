import 'package:tryzeon/core/data/utils/json_diff.dart';
import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/store/data/mappers/store_mappr.dart';
import 'package:tryzeon/feature/store/profile/data/datasources/store_profile_local_datasource.dart';
import 'package:tryzeon/feature/store/profile/data/datasources/store_profile_remote_datasource.dart';
import 'package:tryzeon/feature/store/profile/data/dtos/store_profile_dto.dart';
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
            case CacheHit<StoreProfile>(:final data):
              return Ok(data);
            case CacheEmpty<StoreProfile>():
            case CacheMiss<StoreProfile>():
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

      final profile = _mappr.convert<StoreProfileDto, StoreProfile>(remoteProfile);

      // 3. Update Cache
      try {
        await _localDataSource.saveStoreProfile(profile);
      } catch (e, stackTrace) {
        AppLogger.warning('Failed to save store profile to cache', e, stackTrace);
      }

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
  }) async {
    try {
      final changes = jsonDiff(
        _mappr.convert<StoreProfile, StoreProfileDto>(original).toJson(),
        _mappr.convert<StoreProfile, StoreProfileDto>(target).toJson(),
      );
      if (changes.isEmpty) return const Ok(null);

      await _remoteDataSource.updateStoreProfile(changes);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update store profile', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }

    await _refreshCache();
    return const Ok(null);
  }

  Future<void> _refreshCache() async {
    try {
      final remoteProfile = await _remoteDataSource.getStoreProfile();
      if (remoteProfile == null) {
        await _localDataSource.invalidateStoreProfile();
        return;
      }
      await _localDataSource.saveStoreProfile(
        _mappr.convert<StoreProfileDto, StoreProfile>(remoteProfile),
      );
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Store profile refresh failed, invalidating cache',
        e,
        stackTrace,
      );
      try {
        await _localDataSource.invalidateStoreProfile();
      } catch (e, stackTrace) {
        AppLogger.error('Failed to invalidate store profile cache', e, stackTrace);
      }
    }
  }
}
