import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/feature/store/data/mappers/store_mappr.dart';
import 'package:tryzeon/feature/store/profile/data/collections/store_profile_cache.dart';
import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart';

class StoreProfileLocalDataSource {
  StoreProfileLocalDataSource(this._isarService, this._cacheEntryLocalDataSource);

  final IsarService _isarService;
  final CacheEntryLocalDataSource _cacheEntryLocalDataSource;
  static const _mappr = StoreMappr();
  static const cacheKey = 'store_profile';

  Future<CacheLookup<StoreProfile>> getStoreProfile() async {
    final isar = await _isarService.db;
    final cacheStatus = await _cacheEntryLocalDataSource.getEntryStatus(
      cacheKey,
      staleDuration: AppConstants.staleDurationStoreProfile,
    );
    if (cacheStatus == null) return const CacheMiss();

    if (cacheStatus == CacheEntryStatus.empty) {
      return const CacheEmpty();
    }

    final collection = await isar.storeProfileCaches.where().findFirst();
    if (collection == null) return const CacheMiss();

    return CacheHit(_mappr.convert<StoreProfileCache, StoreProfile>(collection));
  }

  Future<void> saveStoreProfile(final StoreProfile profile) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.storeProfileCaches.clear();
      final collection = _mappr.convert<StoreProfile, StoreProfileCache>(profile);
      await isar.storeProfileCaches.put(collection);
    });
    await _cacheEntryLocalDataSource.markHasData(cacheKey);
  }

  Future<void> markStoreProfileAbsent() async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.storeProfileCaches.clear();
    });
    await _cacheEntryLocalDataSource.markEmpty(cacheKey);
  }

  Future<void> invalidateStoreProfile() => _cacheEntryLocalDataSource.remove(cacheKey);
}
