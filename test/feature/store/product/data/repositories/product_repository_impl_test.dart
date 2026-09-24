import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/data/collections/cache_entry.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/domain/services/cache_service.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/store/product/data/collections/product_cache.dart';
import 'package:tryzeon/feature/store/product/data/datasources/product_local_datasource.dart';
import 'package:tryzeon/feature/store/product/data/datasources/product_remote_datasource.dart';
import 'package:tryzeon/feature/store/product/data/dtos/create_product_request.dart';
import 'package:tryzeon/feature/store/product/data/dtos/product_dto.dart';
import 'package:tryzeon/feature/store/product/data/repositories/product_repository_impl.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:typed_result/typed_result.dart';

import '../../../../../support/isar_test_harness.dart';

class _FakeRemote implements ProductRemoteDataSource {
  _FakeRemote(this.product);

  final ProductDto product;
  int listCalls = 0;
  int getCalls = 0;
  CreateProductRequest? inserted;

  @override
  Future<List<ProductDto>> listProducts({required final String storeId}) async {
    listCalls++;
    return [product];
  }

  @override
  Future<List<String>> uploadProductImages({
    required final String storeId,
    required final String productId,
    required final List<File> images,
  }) async => const [];

  @override
  Future<void> insertProduct(final CreateProductRequest request) async {
    inserted = request;
  }

  @override
  Future<ProductDto> getProduct(final String productId) async {
    getCalls++;
    return product;
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

  Future<void> seedCache({
    final String garmentType = 'one_piece',
    final String? status = 'active',
    final String? gender = 'female',
    final String? fit = 'regular',
    final List<String>? seasons = const ['summer'],
    final List<String>? styles = const ['korean'],
  }) => harness.isar.writeTxn(() async {
    await harness.isar.productCaches.putByProductId(
      ProductCache()
        ..productId = 'p1'
        ..storeId = 's1'
        ..name = '碎花洋裝'
        ..categoryId = 'c1'
        ..garmentType = garmentType
        ..price = 1280
        ..imagePaths = ['p1.jpg']
        ..imageUrls = ['https://cdn/p1.jpg']
        ..status = status
        ..gender = gender
        ..fit = fit
        ..seasons = seasons
        ..styles = styles
        ..createdAt = DateTime(2026)
        ..updatedAt = DateTime(2026),
    );
    await harness.isar.cacheEntrys.putByCacheKey(
      CacheEntry()
        ..cacheKey = ProductLocalDataSource.cacheKeyForStore('s1')
        ..status = CacheEntryStatus.hasData.name
        ..fetchedAt = DateTime.now(),
    );
    await harness.isar.cacheEntrys.putByCacheKey(
      CacheEntry()
        ..cacheKey = ProductLocalDataSource.cacheKeyForProduct('p1')
        ..status = CacheEntryStatus.hasData.name
        ..fetchedAt = DateTime.now(),
    );
  });

  final remoteProduct = ProductDto(
    id: 'p1',
    storeId: 's1',
    name: '碎花洋裝',
    categoryId: 'c1',
    garmentType: GarmentType.onePiece,
    price: 1280,
    imagePaths: const ['p1.jpg'],
    imageUrls: const ['https://cdn/p1.jpg'],
    status: ProductStatus.active,
    gender: ProductGender.female,
    fit: ProductFit.regular,
    seasons: const [ProductSeason.summer],
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  ProductRepositoryImpl buildRepository(final _FakeRemote remote) =>
      ProductRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: ProductLocalDataSource(
          harness.service,
          _NoopCacheService(),
          CacheEntryLocalDataSource(harness.service),
        ),
      );

  test('listProducts re-fetches when a cached garment type no longer decodes', () async {
    await seedCache(garmentType: 'dress');

    final remote = _FakeRemote(remoteProduct);
    final products = (await buildRepository(remote).listProducts(storeId: 's1')).get()!;

    expect(remote.listCalls, 1);
    expect(products.single.garmentType, GarmentType.onePiece);

    final cached = await harness.isar.productCaches.getByProductId('p1');
    expect(cached!.garmentType, 'one_piece');
  });

  test('listProducts re-fetches when a cached season no longer decodes', () async {
    await seedCache(seasons: const ['summer', 'monsoon']);

    final remote = _FakeRemote(remoteProduct);
    final products = (await buildRepository(remote).listProducts(storeId: 's1')).get()!;

    expect(remote.listCalls, 1);
    expect(products.single.seasons, {ProductSeason.summer});

    final cached = await harness.isar.productCaches.getByProductId('p1');
    expect(cached!.seasons, ['summer']);
  });

  test('getProductById re-fetches when a cached fit no longer decodes', () async {
    await seedCache(fit: 'skinny');

    final remote = _FakeRemote(remoteProduct);
    final product = (await buildRepository(remote).getProductById('p1')).get()!;

    expect(remote.getCalls, 1);
    expect(product.fit, ProductFit.regular);

    final cached = await harness.isar.productCaches.getByProductId('p1');
    expect(cached!.fit, 'regular');
  });

  test('getProductById re-fetches when a cached status no longer decodes', () async {
    await seedCache(status: 'draft');

    final remote = _FakeRemote(remoteProduct);
    final product = (await buildRepository(remote).getProductById('p1')).get()!;

    expect(remote.getCalls, 1);
    expect(product.status, ProductStatus.active);
  });

  test('serves the cache untouched when every cached value decodes', () async {
    await seedCache();

    final remote = _FakeRemote(remoteProduct);
    final products = (await buildRepository(remote).listProducts(storeId: 's1')).get()!;

    expect(remote.listCalls, 0);
    expect(products.single.garmentType, GarmentType.onePiece);
    expect(products.single.gender, ProductGender.female);
    expect(products.single.fit, ProductFit.regular);
    expect(products.single.seasons, {ProductSeason.summer});
  });

  test('null cached enums stay null instead of counting as undecodable', () async {
    await seedCache(status: null, gender: null, fit: null, seasons: null, styles: null);

    final remote = _FakeRemote(remoteProduct);
    final products = (await buildRepository(remote).listProducts(storeId: 's1')).get()!;

    expect(remote.listCalls, 0);
    expect(products.single.fit, isNull);
    expect(products.single.seasons, isNull);
    expect(products.single.status, ProductStatus.active);
    expect(products.single.gender, ProductGender.unisex);
  });

  test('createProduct sends styles and seasons in enum declaration order', () async {
    final remote = _FakeRemote(remoteProduct);

    final result = await buildRepository(remote).createProduct(
      const CreateProductParams(
        storeId: 's1',
        draft: ProductDraft(
          name: '碎花洋裝',
          categoryId: 'c1',
          garmentType: GarmentType.onePiece,
          price: 1280,
          styles: {ClothingStyle.western, ClothingStyle.japanese},
          seasons: {ProductSeason.winter, ProductSeason.spring},
        ),
        images: [],
        sizes: [],
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(remote.inserted!.styles, [ClothingStyle.japanese, ClothingStyle.western]);
    expect(remote.inserted!.seasons, [ProductSeason.spring, ProductSeason.winter]);
  });
}
