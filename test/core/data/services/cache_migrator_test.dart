import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/data/collections/cache_entry.dart';
import 'package:tryzeon/core/data/collections/cache_schema.dart';
import 'package:tryzeon/core/data/services/cache_migrator.dart';
import 'package:tryzeon/feature/common/product_category/data/collections/product_category_cache.dart';
import 'package:tryzeon/feature/personal/profile/data/collections/user_profile_cache.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/collections/wardrobe_item_cache.dart';
import 'package:tryzeon/feature/store/product/data/collections/product_cache.dart';

void main() {
  late Directory dir;
  late Isar isar;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('cache_migrator_test');
    isar = await Isar.open(
      [
        CacheSchemaSchema,
        CacheEntrySchema,
        ProductCategoryCacheSchema,
        WardrobeItemCacheSchema,
        ProductCacheSchema,
        UserProfileCacheSchema,
      ],
      directory: dir.path,
      inspector: false,
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    await dir.delete(recursive: true);
  });

  CacheEntry entry(final String key, final String status) => CacheEntry()
    ..cacheKey = key
    ..status = status
    ..fetchedAt = DateTime(2026, 1, 1);

  Future<void> seedPreUpgradeState() => isar.writeTxn(() async {
    await isar.productCategoryCaches.put(
      ProductCategoryCache()
        ..categoryId = 'c1'
        ..code = ''
        ..name = '長褲'
        ..defaultGarmentType = 'pants',
    );
    await isar.wardrobeItemCaches.put(
      WardrobeItemCache()
        ..itemId = 'w1'
        ..imagePath = 'p'
        ..garmentType = ''
        ..createdAt = DateTime(2026)
        ..updatedAt = DateTime(2026),
    );
    await isar.productCaches.put(
      ProductCache()
        ..productId = 'p1'
        ..storeId = 's1'
        ..name = 'x'
        ..categoryId = 'c1'
        ..garmentType = ''
        ..price = 1
        ..imagePaths = []
        ..imageUrls = []
        ..createdAt = DateTime(2026)
        ..updatedAt = DateTime(2026),
    );
    await isar.userProfileCaches.put(
      UserProfileCache()
        ..userId = 'u1'
        ..name = 'x'
        ..createdAt = DateTime(2026)
        ..updatedAt = DateTime(2026)
        ..isOnboarded = true,
    );
    await isar.cacheEntrys.putAll([
      entry('product_categories', 'hasData'),
      entry('wardrobe_items', 'empty'),
      entry('store_products:s1', 'hasData'),
      entry('store_product:p1', 'hasData'),
      entry('user_profile', 'hasData'),
    ]);
  });

  test('clears every collection and entry on first run', () async {
    await seedPreUpgradeState();

    await CacheMigrator.run(isar);

    expect(await isar.productCategoryCaches.count(), 0);
    expect(await isar.wardrobeItemCaches.count(), 0);
    expect(await isar.productCaches.count(), 0);
    expect(await isar.userProfileCaches.count(), 0);
    expect(await isar.cacheEntrys.count(), 0);
    expect((await isar.cacheSchemas.get(0))?.version, AppConstants.cacheSchemaVersion);
  });

  test('is a no-op once the version is current', () async {
    await CacheMigrator.run(isar);
    await seedPreUpgradeState();

    await CacheMigrator.run(isar);

    expect(await isar.productCategoryCaches.count(), 1);
    expect(await isar.cacheEntrys.count(), 5);
  });

  test('clears again when the version is bumped', () async {
    await isar.writeTxn(
      () => isar.cacheSchemas.put(
        CacheSchema()
          ..id = 0
          ..version = AppConstants.cacheSchemaVersion - 1,
      ),
    );
    await seedPreUpgradeState();

    await CacheMigrator.run(isar);

    expect(await isar.productCaches.count(), 0);
    expect((await isar.cacheSchemas.get(0))?.version, AppConstants.cacheSchemaVersion);
  });
}
