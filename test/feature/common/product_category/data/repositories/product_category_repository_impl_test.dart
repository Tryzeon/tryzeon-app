import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/data/collections/cache_entry.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_category/data/collections/product_category_cache.dart';
import 'package:tryzeon/feature/common/product_category/data/datasources/product_category_local_datasource.dart';
import 'package:tryzeon/feature/common/product_category/data/datasources/product_category_remote_datasource.dart';
import 'package:tryzeon/feature/common/product_category/data/dtos/product_category_dto.dart';
import 'package:tryzeon/feature/common/product_category/data/repositories/product_category_repository_impl.dart';
import 'package:typed_result/typed_result.dart';

import '../../../../../support/isar_test_harness.dart';

class _FakeRemote implements ProductCategoryRemoteDataSource {
  _FakeRemote(this.categories);

  final List<ProductCategoryDto> categories;
  int calls = 0;

  @override
  Future<List<ProductCategoryDto>> getProductCategories() async {
    calls++;
    return categories;
  }

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

  Future<void> seedCache({
    required final String defaultGarmentType,
    final String? gender = 'female',
  }) => harness.isar.writeTxn(() async {
    await harness.isar.productCategoryCaches.putByCategoryId(
      ProductCategoryCache()
        ..categoryId = 'c1'
        ..code = 'one_piece'
        ..name = '洋裝·連身裙'
        ..defaultGarmentType = defaultGarmentType
        ..gender = gender,
    );
    await harness.isar.cacheEntrys.putByCacheKey(
      CacheEntry()
        ..cacheKey = ProductCategoryLocalDataSource.cacheKey
        ..status = CacheEntryStatus.hasData.name
        ..fetchedAt = DateTime.now(),
    );
  });

  ProductCategoryRepositoryImpl buildRepository(final _FakeRemote remote) =>
      ProductCategoryRepositoryImpl(
        remote,
        ProductCategoryLocalDataSource(
          harness.service,
          CacheEntryLocalDataSource(harness.service),
        ),
      );

  final remoteCategory = const ProductCategoryDto(
    id: 'c1',
    code: 'one_piece',
    name: '洋裝·連身裙',
    defaultGarmentType: GarmentType.onePiece,
    gender: ProductGender.female,
  );

  test(
    're-fetches when a cached default garment type no longer decodes',
    () async {
      await seedCache(defaultGarmentType: 'dress');

      final remote = _FakeRemote([remoteCategory]);
      final categories = (await buildRepository(
        remote,
      ).getProductCategories()).get()!;

      expect(remote.calls, 1);
      expect(categories.single.defaultGarmentType, GarmentType.onePiece);

      final cached = await harness.isar.productCategoryCaches.getByCategoryId(
        'c1',
      );
      expect(cached!.defaultGarmentType, 'one_piece');
    },
  );

  test('re-fetches when a cached gender no longer decodes', () async {
    await seedCache(defaultGarmentType: 'one_piece', gender: 'nonbinary');

    final remote = _FakeRemote([remoteCategory]);
    final categories = (await buildRepository(
      remote,
    ).getProductCategories()).get()!;

    expect(remote.calls, 1);
    expect(categories.single.gender, ProductGender.female);

    final cached = await harness.isar.productCategoryCaches.getByCategoryId(
      'c1',
    );
    expect(cached!.gender, 'female');
  });

  test('serves the cache untouched when every cached value decodes', () async {
    await seedCache(defaultGarmentType: 'one_piece');

    final remote = _FakeRemote([]);
    final categories = (await buildRepository(
      remote,
    ).getProductCategories()).get()!;

    expect(remote.calls, 0);
    expect(categories.single.defaultGarmentType, GarmentType.onePiece);
    expect(categories.single.gender, ProductGender.female);
  });

  test(
    'force refresh bypasses a valid cache and rewrites it from remote',
    () async {
      await seedCache(defaultGarmentType: 'top');

      final remote = _FakeRemote([remoteCategory]);
      final categories = (await buildRepository(
        remote,
      ).getProductCategories(forceRefresh: true)).get()!;

      expect(remote.calls, 1);
      expect(categories.single.defaultGarmentType, GarmentType.onePiece);

      final cached = await harness.isar.productCategoryCaches.getByCategoryId(
        'c1',
      );
      expect(cached!.defaultGarmentType, 'one_piece');
    },
  );

  test('a null cached gender stays null and falls back to unisex', () async {
    await seedCache(defaultGarmentType: 'top', gender: null);

    final remote = _FakeRemote([]);
    final categories = (await buildRepository(
      remote,
    ).getProductCategories()).get()!;

    expect(remote.calls, 0);
    expect(categories.single.gender, ProductGender.unisex);
  });
}
