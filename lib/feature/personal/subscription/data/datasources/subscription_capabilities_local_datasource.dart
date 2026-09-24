import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/feature/personal/data/mappers/personal_mappr.dart';
import 'package:tryzeon/feature/personal/subscription/data/collections/subscription_tier_cache.dart';
import 'package:tryzeon/feature/personal/subscription/domain/entities/subscription_capabilities.dart';

class SubscriptionCapabilitiesLocalDataSource {
  SubscriptionCapabilitiesLocalDataSource(
    this._isarService,
    this._cacheEntryLocalDataSource,
  );

  final IsarService _isarService;
  final CacheEntryLocalDataSource _cacheEntryLocalDataSource;

  static const _mappr = PersonalMappr();
  static const _baseCacheKey = 'subscription_tier_capabilities';

  static String cacheKeyForTier(final AppSubscriptionTier tier) =>
      '${_baseCacheKey}_${tier.value}';

  Future<CacheLookup<SubscriptionCapabilities>> getTierCapabilities(
    final AppSubscriptionTier tier,
  ) async {
    final cacheStatus = await _cacheEntryLocalDataSource.getEntryStatus(
      cacheKeyForTier(tier),
      staleDuration: AppConstants.staleDurationSubscriptionTier,
    );
    if (cacheStatus == null) return const CacheMiss();
    if (cacheStatus == CacheEntryStatus.empty) return const CacheEmpty();

    final isar = await _isarService.db;
    final collection = await isar.subscriptionTierCaches.getByTier(tier.value);

    if (collection == null) return const CacheMiss();

    return CacheHit(
      _mappr.convert<SubscriptionTierCache, SubscriptionCapabilities>(collection),
    );
  }

  Future<void> saveTierCapabilities(
    final AppSubscriptionTier tier,
    final SubscriptionCapabilities capabilities,
  ) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      final collection =
          _mappr.convert<SubscriptionCapabilities, SubscriptionTierCache>(capabilities)
            ..tier = tier.value;
      await isar.subscriptionTierCaches.putByTier(collection);
    });
    await _cacheEntryLocalDataSource.markHasData(cacheKeyForTier(tier));
  }
}
