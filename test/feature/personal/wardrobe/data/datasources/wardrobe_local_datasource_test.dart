import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/core/domain/services/image_file_cache.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/datasources/wardrobe_local_datasource.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';

import '../../../../../support/isar_test_harness.dart';

class _NoopImageFileCache implements ImageFileCache {
  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  late TestIsar harness;

  setUp(() async {
    harness = await openTestIsar();
  });

  tearDown(() async {
    await harness.dispose();
  });

  WardrobeLocalDataSource build() => WardrobeLocalDataSource(
    harness.service,
    _NoopImageFileCache(),
    CacheEntryLocalDataSource(harness.service),
  );

  test('reads back exactly the entities it saved, newest first', () async {
    final newer = WardrobeItem(
      id: 'w1',
      imagePath: 'w1.jpg',
      garmentType: GarmentType.onePiece,
      tags: const ['linen', 'white'],
      createdAt: DateTime(2026, 2),
      updatedAt: DateTime(2026, 3),
    );
    final older = WardrobeItem(
      id: 'w2',
      imagePath: 'w2.jpg',
      garmentType: GarmentType.top,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    final local = build();

    await local.saveWardrobeItems([older, newer]);

    final lookup = await local.getWardrobeItems();
    expect((lookup as CacheHit<List<WardrobeItem>>).data, [newer, older]);
  });

  test('saveWardrobeItem upserts by id', () async {
    final item = WardrobeItem(
      id: 'w1',
      imagePath: 'w1.jpg',
      garmentType: GarmentType.top,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    final local = build();

    await local.saveWardrobeItems([item]);
    await local.saveWardrobeItem(item.copyWith(tags: const ['cotton']));

    final lookup = await local.getWardrobeItems();
    expect((lookup as CacheHit<List<WardrobeItem>>).data, [
      item.copyWith(tags: const ['cotton']),
    ]);
  });

  group('list entry', () {
    CacheEntryLocalDataSource entries() =>
        CacheEntryLocalDataSource(harness.service);

    test('saveWardrobeItem leaves an absent list entry absent', () async {
      final item = WardrobeItem(
        id: 'w1',
        imagePath: 'w1.jpg',
        garmentType: GarmentType.top,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      await build().saveWardrobeItem(item);

      expect(
        await entries().getEntryStatus(WardrobeLocalDataSource.cacheKey),
        isNull,
      );
    });

    test('saveWardrobeItem keeps a cached list complete', () async {
      final w1 = WardrobeItem(
        id: 'w1',
        imagePath: 'w1.jpg',
        garmentType: GarmentType.top,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final w2 = WardrobeItem(
        id: 'w2',
        imagePath: 'w2.jpg',
        garmentType: GarmentType.pants,
        createdAt: DateTime(2026, 2),
        updatedAt: DateTime(2026, 2),
      );
      final local = build();
      await local.saveWardrobeItems([w1]);

      await local.saveWardrobeItem(w2);

      expect(
        await entries().getEntryStatus(WardrobeLocalDataSource.cacheKey),
        CacheEntryStatus.hasData,
      );
      final lookup = await local.getWardrobeItems();
      expect(
        (lookup as CacheHit<List<WardrobeItem>>).data,
        unorderedEquals([w1, w2]),
      );
    });

    test('deleteWardrobeItem leaves an absent list entry absent', () async {
      await build().deleteWardrobeItem('w1');

      expect(
        await entries().getEntryStatus(WardrobeLocalDataSource.cacheKey),
        isNull,
      );
    });
  });
}
