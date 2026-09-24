import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/data/mappers/personal_mappr.dart';
import 'package:tryzeon/feature/personal/subscription/data/datasources/subscription_capabilities_local_datasource.dart';
import 'package:tryzeon/feature/personal/subscription/data/datasources/subscription_capabilities_remote_datasource.dart';
import 'package:tryzeon/feature/personal/subscription/data/dtos/subscription_tier_dto.dart';
import 'package:tryzeon/feature/personal/subscription/domain/entities/subscription_capabilities.dart';
import 'package:tryzeon/feature/personal/subscription/domain/repositories/subscription_capabilities_repository.dart';
import 'package:typed_result/typed_result.dart';

class SubscriptionCapabilitiesRepositoryImpl
    implements SubscriptionCapabilitiesRepository {
  SubscriptionCapabilitiesRepositoryImpl({
    required final SubscriptionCapabilitiesRemoteDataSource remoteDataSource,
    required final SubscriptionCapabilitiesLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final SubscriptionCapabilitiesRemoteDataSource _remoteDataSource;
  final SubscriptionCapabilitiesLocalDataSource _localDataSource;
  static const _mappr = PersonalMappr();

  @override
  Future<Result<SubscriptionCapabilities, Failure>> getCapabilitiesForTier(
    final AppSubscriptionTier tier,
  ) async {
    try {
      // 1. Try local cache
      try {
        final cached = await _localDataSource.getTierCapabilities(tier);
        switch (cached) {
          case CacheHit<SubscriptionCapabilities>(:final data):
            return Ok(data);
          case CacheEmpty<SubscriptionCapabilities>():
          case CacheMiss<SubscriptionCapabilities>():
            break;
        }
      } catch (e, stackTrace) {
        AppLogger.warning(
          'Local subscription tier cache read failed, falling back to remote',
          e,
          stackTrace,
        );
      }

      // 2. Fetch from remote
      final capabilities = _mappr.convert<SubscriptionTierDto, SubscriptionCapabilities>(
        await _remoteDataSource.getTierCapabilities(tier),
      );

      // 3. Persist to local cache
      try {
        await _localDataSource.saveTierCapabilities(tier, capabilities);
      } catch (e, stackTrace) {
        AppLogger.warning(
          'Failed to save subscription tier capabilities to cache',
          e,
          stackTrace,
        );
      }

      return Ok(capabilities);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to load subscription capabilities for ${tier.value}',
        e,
        stackTrace,
      );
      return Err(
        ServerFailure('Failed to load subscription capabilities for ${tier.value}'),
      );
    }
  }
}
