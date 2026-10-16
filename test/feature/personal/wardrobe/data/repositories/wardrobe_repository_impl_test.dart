import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/data/collections/cache_entry.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/data/services/image_file_cache.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/collections/wardrobe_item_cache.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/datasources/wardrobe_local_datasource.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/datasources/wardrobe_remote_datasource.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/dtos/create_wardrobe_item_request.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/dtos/update_wardrobe_item_request.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/dtos/wardrobe_item_dto.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/repositories/wardrobe_repository_impl.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/new_wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item_update.dart';
import 'package:typed_result/typed_result.dart';

import '../../../../../support/isar_test_harness.dart';

class _FakeRemote implements WardrobeRemoteDataSource {
  _FakeRemote(this.items);

  final List<WardrobeItemDto> items;
  int calls = 0;

  @override
  Future<List<WardrobeItemDto>> getWardrobeItems() async {
    calls++;
    return items;
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeRemoteCreate implements WardrobeRemoteDataSource {
  int listCalls = 0;

  @override
  Future<WardrobeItemDto> createWardrobeItem(
    final CreateWardrobeItemRequest request,
  ) async => WardrobeItemDto(
    id: request.id,
    imagePath: request.imagePath,
    garmentType: request.garmentType,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  @override
  Future<List<WardrobeItemDto>> getWardrobeItems() async {
    listCalls++;
    return [];
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeRemoteUpdate implements WardrobeRemoteDataSource {
  @override
  Future<WardrobeItemDto> updateWardrobeItem({
    required final String id,
    required final UpdateWardrobeItemRequest request,
  }) async => WardrobeItemDto(
    id: id,
    imagePath: '$id.jpg',
    garmentType: request.garmentType ?? GarmentType.top,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FailingSaveLocal extends WardrobeLocalDataSource {
  _FailingSaveLocal(
    super.isarService,
    super.imageFileCache,
    super.cacheEntryLocalDataSource,
  );

  @override
  Future<void> saveWardrobeItem(final WardrobeItem item) async {
    throw Exception('cache write failed');
  }
}

class _NoopImageFileCache implements ImageFileCache {
  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  late TestIsar harness;

  setUp(() async {
    harness = await openTestIsar();
  });

  tearDown(() async {
    await harness.dispose();
  });

  Future<void> seedCache(final String garmentType) =>
      harness.isar.writeTxn(() async {
        await harness.isar.wardrobeItemCaches.putByItemId(
          WardrobeItemCache()
            ..itemId = 'w1'
            ..imagePath = 'w1.jpg'
            ..garmentType = garmentType
            ..createdAt = DateTime(2026)
            ..updatedAt = DateTime(2026),
        );
        await harness.isar.cacheEntrys.putByCacheKey(
          CacheEntry()
            ..cacheKey = WardrobeLocalDataSource.cacheKey
            ..status = CacheEntryStatus.hasData.name
            ..fetchedAt = DateTime.now(),
        );
      });

  WardrobeRepositoryImpl buildRepository(
    final WardrobeRemoteDataSource remote,
  ) => WardrobeRepositoryImpl(
    remoteDataSource: remote,
    localDataSource: WardrobeLocalDataSource(
      harness.service,
      _NoopImageFileCache(),
      CacheEntryLocalDataSource(harness.service),
    ),
  );

  test(
    're-fetches from remote when a cached garment type no longer decodes',
    () async {
      await seedCache('dress');

      final remote = _FakeRemote([
        WardrobeItemDto(
          id: 'w1',
          imagePath: 'w1.jpg',
          garmentType: GarmentType.onePiece,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ]);

      final items = (await buildRepository(remote).getWardrobeItems()).get()!;

      expect(remote.calls, 1);
      expect(items.single.garmentType, GarmentType.onePiece);

      final cached = await harness.isar.wardrobeItemCaches.getByItemId('w1');
      expect(cached!.garmentType, 'one_piece');
    },
  );

  test('serves the cache untouched when every cached value decodes', () async {
    await seedCache('top');

    final remote = _FakeRemote([]);

    final items = (await buildRepository(remote).getWardrobeItems()).get()!;

    expect(remote.calls, 0);
    expect(items.single.garmentType, GarmentType.top);
  });

  const newItem = NewWardrobeItem(
    id: 'w2',
    imagePath: 'w2.jpg',
    garmentType: GarmentType.top,
    tags: [],
  );

  test(
    'createWardrobeItem adds the returned item to the cache without refetching the list',
    () async {
      await seedCache('top');
      final remote = _FakeRemoteCreate();

      final result = await buildRepository(remote).createWardrobeItem(newItem);

      expect(result.isSuccess, isTrue);
      expect(remote.listCalls, 0);
      expect(await harness.isar.wardrobeItemCaches.count(), 2);
      expect(
        await harness.isar.wardrobeItemCaches.getByItemId('w2'),
        isNotNull,
      );
    },
  );

  test(
    'createWardrobeItem succeeds and drops the cache when caching the item fails',
    () async {
      await seedCache('top');
      final repository = WardrobeRepositoryImpl(
        remoteDataSource: _FakeRemoteCreate(),
        localDataSource: _FailingSaveLocal(
          harness.service,
          _NoopImageFileCache(),
          CacheEntryLocalDataSource(harness.service),
        ),
      );

      final result = await repository.createWardrobeItem(newItem);

      expect(result.isSuccess, isTrue);
      expect(
        await CacheEntryLocalDataSource(
          harness.service,
        ).getEntryStatus(WardrobeLocalDataSource.cacheKey),
        isNull,
      );
      expect(await harness.isar.wardrobeItemCaches.count(), 0);
    },
  );

  test(
    'updateWardrobeItem succeeds and drops the cache when the cache write fails',
    () async {
      await seedCache('top');

      final repository = WardrobeRepositoryImpl(
        remoteDataSource: _FakeRemoteUpdate(),
        localDataSource: _FailingSaveLocal(
          harness.service,
          _NoopImageFileCache(),
          CacheEntryLocalDataSource(harness.service),
        ),
      );

      final result = await repository.updateWardrobeItem(
        'w1',
        const WardrobeItemUpdate(garmentType: GarmentType.pants),
      );

      expect(result.get()?.garmentType, GarmentType.pants);
      expect(
        await CacheEntryLocalDataSource(
          harness.service,
        ).getEntryStatus(WardrobeLocalDataSource.cacheKey),
        isNull,
      );
    },
  );
}
