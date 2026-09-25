import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/data/collections/cache_entry.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/domain/services/cache_service.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/collections/wardrobe_item_cache.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/datasources/wardrobe_local_datasource.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/datasources/wardrobe_remote_datasource.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/dtos/create_wardrobe_item_request.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/dtos/wardrobe_item_dto.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/repositories/wardrobe_repository_impl.dart';
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

class _FakeRemoteFailingRefresh implements WardrobeRemoteDataSource {
  @override
  Future<void> createWardrobeItem(final CreateWardrobeItemRequest request) async {}

  @override
  Future<List<WardrobeItemDto>> getWardrobeItems() async {
    throw Exception('refresh failed');
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _NoopCacheService implements CacheService {
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

  Future<void> seedCache(final String garmentType) => harness.isar.writeTxn(() async {
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

  WardrobeRepositoryImpl buildRepository(final WardrobeRemoteDataSource remote) =>
      WardrobeRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: WardrobeLocalDataSource(
          harness.service,
          _NoopCacheService(),
          CacheEntryLocalDataSource(harness.service),
        ),
      );

  test('re-fetches from remote when a cached garment type no longer decodes', () async {
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
  });

  test('serves the cache untouched when every cached value decodes', () async {
    await seedCache('top');

    final remote = _FakeRemote([]);

    final items = (await buildRepository(remote).getWardrobeItems()).get()!;

    expect(remote.calls, 0);
    expect(items.single.garmentType, GarmentType.top);
  });

  test('createWardrobeItem invalidates the cache when the refresh fails', () async {
    await seedCache('top');

    final result = await buildRepository(_FakeRemoteFailingRefresh()).createWardrobeItem(
      id: 'w2',
      imagePath: 'w2.jpg',
      garmentType: GarmentType.top,
      tags: const [],
    );

    expect(result.isSuccess, isTrue);
    expect(
      await CacheEntryLocalDataSource(
        harness.service,
      ).getEntryStatus(WardrobeLocalDataSource.cacheKey),
      isNull,
    );
    expect(await harness.isar.wardrobeItemCaches.count(), 0);
  });
}
