import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/data/collections/cache_entry.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/public_image_url.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_color/data/collections/product_color_embedded.dart';
import 'package:tryzeon/feature/common/product_color/data/dtos/product_color_dto.dart';
import 'package:tryzeon/feature/store/product/data/collections/product_cache.dart';
import 'package:tryzeon/feature/store/product/data/datasources/product_local_datasource.dart';
import 'package:tryzeon/feature/store/product/data/datasources/product_remote_datasource.dart';
import 'package:tryzeon/feature/store/product/data/dtos/create_product_color_request.dart';
import 'package:tryzeon/feature/store/product/data/dtos/create_product_request.dart';
import 'package:tryzeon/feature/store/product/data/dtos/create_product_size_request.dart';
import 'package:tryzeon/feature/store/product/data/dtos/product_dto.dart';
import 'package:tryzeon/feature/store/product/data/repositories/product_repository_impl.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_color_diff.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_size_diff.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_update_plan.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/color_item.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/image_item.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/size_item.dart';
import 'package:typed_result/typed_result.dart';

import '../../../../../support/isar_test_harness.dart';
import '../../../../../support/product_color_fixtures.dart';

class _FakeRemote implements ProductRemoteDataSource {
  _FakeRemote(this.product);

  final ProductDto product;
  int listCalls = 0;
  int getCalls = 0;
  CreateProductRequest? inserted;
  List<CreateProductColorRequest>? insertedColors;
  final Map<String, Map<String, dynamic>> colorChanges = {};
  Object? getError;
  Object? updateError;
  final List<(String, Map<String, dynamic>)> colorWrites = [];
  final List<String> writes = [];

  @override
  Future<List<ProductDto>> listProducts({required final String storeId}) async {
    listCalls++;
    return [product];
  }

  @override
  Future<void> insertProduct(final CreateProductRequest request) async {
    inserted = request;
    writes.add('insertProduct');
  }

  @override
  Future<void> insertProductColors(
    final List<CreateProductColorRequest> requests,
  ) async {
    insertedColors = requests;
    writes.add('insertProductColors');
  }

  @override
  Future<void> insertProductSizes(
    final List<CreateProductSizeRequest> requests,
  ) async => writes.add('insertProductSizes');

  @override
  Future<ProductDto> getProduct(final String productId) async {
    getCalls++;
    if (getError case final error?) throw error;
    return product;
  }

  @override
  Future<void> deleteProductSize(final String sizeId) async =>
      writes.add('deleteSize:$sizeId');

  @override
  Future<void> insertProductSize(
    final CreateProductSizeRequest request,
  ) async => writes.add('insertSize:${request.size.name}');

  @override
  Future<void> updateProductColor(
    final String colorId,
    final Map<String, dynamic> changes,
  ) async {
    colorChanges[colorId] = changes;
    colorWrites.add((colorId, changes));
    writes.add('updateColor:$colorId');
  }

  @override
  Future<void> deleteProductColor(final String colorId) async =>
      writes.add('deleteColor:$colorId');

  @override
  Future<void> updateProduct(
    final String productId,
    final Map<String, dynamic> changes,
  ) async {
    if (updateError case final error?) throw error;
    writes.add('updateProduct');
  }

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

  Future<void> seedCache({
    final String garmentType = 'one_piece',
    final String? status = 'active',
    final String? gender = 'female',
    final String? fit = 'regular',
    final List<String>? seasons = const ['summer'],
    final List<String>? styles = const ['casual'],
  }) => harness.isar.writeTxn(() async {
    await harness.isar.productCaches.putByProductId(
      ProductCache()
        ..productId = 'p1'
        ..storeId = 's1'
        ..name = '碎花洋裝'
        ..categoryId = 'c1'
        ..garmentType = garmentType
        ..price = 1280
        ..colors = [
          ProductColorEmbedded()
            ..id = 'k1'
            ..productId = 'p1'
            ..imagePaths = ['p1.jpg']
            ..position = 0
            ..createdAt = DateTime(2026)
            ..updatedAt = DateTime(2026),
        ]
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
  });

  final remoteProduct = ProductDto(
    id: 'p1',
    storeId: 's1',
    name: '碎花洋裝',
    categoryId: 'c1',
    garmentType: GarmentType.onePiece,
    price: 1280,
    colors: [
      ProductColorDto(
        id: 'k1',
        productId: 'p1',
        imagePaths: const ['p1.jpg'],
        position: 0,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    ],
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
          CacheEntryLocalDataSource(harness.service),
        ),
      );

  test(
    'listProducts re-fetches when a cached garment type no longer decodes',
    () async {
      await seedCache(garmentType: 'dress');

      final remote = _FakeRemote(remoteProduct);
      final products = (await buildRepository(
        remote,
      ).listProducts(storeId: 's1')).get()!;

      expect(remote.listCalls, 1);
      expect(products.single.garmentType, GarmentType.onePiece);

      final cached = await harness.isar.productCaches.getByProductId('p1');
      expect(cached!.garmentType, 'one_piece');
    },
  );

  test(
    'listProducts re-fetches when a cached season no longer decodes',
    () async {
      await seedCache(seasons: const ['summer', 'monsoon']);

      final remote = _FakeRemote(remoteProduct);
      final products = (await buildRepository(
        remote,
      ).listProducts(storeId: 's1')).get()!;

      expect(remote.listCalls, 1);
      expect(products.single.seasons, {ProductSeason.summer});

      final cached = await harness.isar.productCaches.getByProductId('p1');
      expect(cached!.seasons, ['summer']);
    },
  );

  test('listProducts re-fetches when a cached fit no longer decodes', () async {
    await seedCache(fit: 'skinny');

    final remote = _FakeRemote(remoteProduct);
    final products = (await buildRepository(
      remote,
    ).listProducts(storeId: 's1')).get()!;

    expect(remote.listCalls, 1);
    expect(products.single.fit, ProductFit.regular);

    final cached = await harness.isar.productCaches.getByProductId('p1');
    expect(cached!.fit, 'regular');
  });

  test(
    'listProducts re-fetches when a cached status no longer decodes',
    () async {
      await seedCache(status: 'draft');

      final remote = _FakeRemote(remoteProduct);
      final products = (await buildRepository(
        remote,
      ).listProducts(storeId: 's1')).get()!;

      expect(remote.listCalls, 1);
      expect(products.single.status, ProductStatus.active);
    },
  );

  test('serves the cache untouched when every cached value decodes', () async {
    await seedCache();

    final remote = _FakeRemote(remoteProduct);
    final products = (await buildRepository(
      remote,
    ).listProducts(storeId: 's1')).get()!;

    expect(remote.listCalls, 0);
    expect(products.single.colors.single.imageUrls, [
      PublicImageUrl.of('p1.jpg'),
    ]);
    expect(products.single.garmentType, GarmentType.onePiece);
    expect(products.single.gender, ProductGender.female);
    expect(products.single.fit, ProductFit.regular);
    expect(products.single.seasons, {ProductSeason.summer});
  });

  test(
    'null cached enums stay null instead of counting as undecodable',
    () async {
      await seedCache(
        status: null,
        gender: null,
        fit: null,
        seasons: null,
        styles: null,
      );

      final remote = _FakeRemote(remoteProduct);
      final products = (await buildRepository(
        remote,
      ).listProducts(storeId: 's1')).get()!;

      expect(remote.listCalls, 0);
      expect(products.single.fit, isNull);
      expect(products.single.seasons, isNull);
      expect(products.single.status, ProductStatus.active);
      expect(products.single.gender, ProductGender.unisex);
    },
  );

  test('listProducts serves an empty cache without calling remote', () async {
    await harness.isar.writeTxn(() async {
      await harness.isar.cacheEntrys.putByCacheKey(
        CacheEntry()
          ..cacheKey = ProductLocalDataSource.cacheKeyForStore('s1')
          ..status = CacheEntryStatus.empty.name
          ..fetchedAt = DateTime.now(),
      );
    });

    final remote = _FakeRemote(remoteProduct);
    final products = (await buildRepository(
      remote,
    ).listProducts(storeId: 's1')).get()!;

    expect(remote.listCalls, 0);
    expect(products, isEmpty);
  });

  test(
    'createProduct sends styles and seasons in enum declaration order',
    () async {
      final remote = _FakeRemote(remoteProduct);

      final result = await buildRepository(remote).createProduct(
        const NewProduct(
          id: 'p1',
          storeId: 's1',
          draft: ProductDraft(
            name: '碎花洋裝',
            categoryId: 'c1',
            garmentType: GarmentType.onePiece,
            price: 1280,
            styles: {ClothingStyle.edgy, ClothingStyle.natural},
            seasons: {ProductSeason.winter, ProductSeason.spring},
          ),
          colors: [
            NewProductColor(imagePaths: ['p1.jpg'], position: 0),
          ],
          sizes: [],
        ),
      );

      expect(result.isSuccess, isTrue);
      final row = remote.inserted!.toJson();
      expect(row['styles'], ['edgy', 'natural']);
      expect(row['seasons'], ['spring', 'winter']);
    },
  );

  test(
    'createProduct writes the product, then its colours, then its sizes',
    () async {
      final remote = _FakeRemote(remoteProduct);

      final result = await buildRepository(remote).createProduct(
        const NewProduct(
          id: 'p1',
          storeId: 's1',
          draft: ProductDraft(
            name: '碎花洋裝',
            categoryId: 'c1',
            garmentType: GarmentType.onePiece,
            price: 1280,
          ),
          colors: [
            NewProductColor(imagePaths: ['p1/a.jpg'], position: 0),
          ],
          sizes: [NewSizeItem(name: 'M')],
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(remote.writes, [
        'insertProduct',
        'insertProductColors',
        'insertProductSizes',
      ]);
      expect(remote.inserted!.toJson(), isNot(contains('image_paths')));
      expect(remote.insertedColors!.single.toJson(), {
        'product_id': 'p1',
        'store_id': 's1',
        'name': null,
        'image_paths': ['p1/a.jpg'],
        'position': 0,
      });
    },
  );

  final original = Product(
    id: 'p1',
    storeId: 's1',
    name: '碎花洋裝',
    categoryId: 'c1',
    garmentType: GarmentType.onePiece,
    price: 1280,
    colors: [
      productColorFixture(imagePaths: const ['a.jpg', 'b.jpg']),
    ],
    sizes: [
      ProductSize(
        id: 'm',
        productId: 'p1',
        name: 'M',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    ],
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  ProductUpdatePlan planFor(
    final List<String> imagePaths,
    final List<SizeItem> sizes, {
    final String name = '碎花洋裝',
  }) => planProductUpdate(
    original: original,
    draft: ProductDraft(
      name: name,
      categoryId: 'c1',
      garmentType: GarmentType.onePiece,
      price: 1280,
    ),
    colors: [
      ColorItem.existing(
        id: original.colors.single.id,
        images: [
          for (final path in imagePaths)
            ImageItem.existing(path: path, url: path),
        ],
      ),
    ],
    uploadedPaths: const [],
    sizes: sizes,
  );

  test(
    'updateProduct writes the image-referencing colour after every other row',
    () async {
      final remote = _FakeRemote(remoteProduct);
      final plan = planFor(
        const ['b.jpg'],
        const [SizeItem.newSize(name: 'L')],
        name: '素面洋裝',
      );

      final result = await buildRepository(remote).updateProduct(
        original: original,
        target: plan.target,
        sizeDiff: plan.sizeDiff,
        colorDiff: plan.colorDiff,
      );

      expect(result.isSuccess, isTrue);
      expect(remote.writes, [
        'deleteSize:m',
        'insertSize:L',
        'updateProduct',
        'updateColor:${original.colors.single.id}',
      ]);
    },
  );

  test(
    'updateProduct leaves the colour images alone when the product row fails',
    () async {
      final remote = _FakeRemote(remoteProduct)
        ..updateError = const SocketException('offline');
      final plan = planFor(
        const ['b.jpg'],
        const [SizeItem.existing(id: 'm', name: 'M')],
        name: '素面洋裝',
      );

      final result = await buildRepository(remote).updateProduct(
        original: original,
        target: plan.target,
        sizeDiff: plan.sizeDiff,
        colorDiff: plan.colorDiff,
      );

      expect(result.getError(), isA<Failure>());
      expect(
        remote.writes.where((final write) => write.startsWith('updateColor:')),
        isEmpty,
      );
    },
  );

  test(
    'updateProduct writes a removed image to the colour, not the product row',
    () async {
      final remote = _FakeRemote(remoteProduct);
      final plan = planFor(
        const ['b.jpg'],
        const [SizeItem.existing(id: 'm', name: 'M')],
      );

      final result = await buildRepository(remote).updateProduct(
        original: original,
        target: plan.target,
        sizeDiff: plan.sizeDiff,
        colorDiff: plan.colorDiff,
      );

      expect(result.isSuccess, isTrue);
      expect(remote.writes, ['updateColor:${original.colors.single.id}']);
      expect(remote.colorChanges, {
        original.colors.single.id: {
          'image_paths': ['b.jpg'],
        },
      });
    },
  );

  test('updateProduct leaves an unchanged colour alone', () async {
    final remote = _FakeRemote(remoteProduct);
    final plan = planFor(
      const ['a.jpg', 'b.jpg'],
      const [SizeItem.existing(id: 'm', name: 'M')],
      name: '素面洋裝',
    );

    final result = await buildRepository(remote).updateProduct(
      original: original,
      target: plan.target,
      sizeDiff: plan.sizeDiff,
      colorDiff: plan.colorDiff,
    );

    expect(result.isSuccess, isTrue);
    expect(remote.writes, ['updateProduct']);
  });

  test('updateProduct skips a size whose row would not change', () async {
    final remote = _FakeRemote(remoteProduct);

    final result = await buildRepository(remote).updateProduct(
      original: original,
      target: original,
      sizeDiff: ProductSizeDiff(
        toAdd: const [],
        toUpdate: [
          ProductSizeUpdate(
            original: original.sizes!.single,
            target: const ExistingSizeItem(id: 'm', name: 'M'),
          ),
        ],
        idsToDelete: const [],
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(remote.writes, isEmpty);
  });

  test(
    'updateProduct succeeds and drops the cache when the refresh fails',
    () async {
      await seedCache();
      final remote = _FakeRemote(remoteProduct)
        ..getError = const SocketException('offline');
      final plan = planFor(const [], const [
        SizeItem.existing(id: 'm', name: 'M'),
      ]);

      final result = await buildRepository(
        remote,
      ).updateProduct(original: original, target: plan.target);

      final entries = CacheEntryLocalDataSource(harness.service);
      expect(result.isSuccess, isTrue);
      expect(result.get(), isNull);
      expect(
        await entries.getEntryStatus(
          ProductLocalDataSource.cacheKeyForStore('s1'),
        ),
        isNull,
      );
      expect(await harness.isar.productCaches.getByProductId('p1'), isNull);
    },
  );

  test(
    'updateProduct fails without refreshing when no row was updated',
    () async {
      final remote = _FakeRemote(remoteProduct)
        ..updateError = const PostgrestException(
          message: 'no rows',
          code: 'PGRST116',
        );

      final result = await buildRepository(remote).updateProduct(
        original: original,
        target: original.copyWith(status: ProductStatus.archived),
      );

      expect(result.getError(), const NotFoundFailure());
      expect(remote.getCalls, 0);
    },
  );

  group('colour diff writes', () {
    ProductColor color(
      final String id,
      final String? name,
      final int position,
    ) => ProductColor(
      id: id,
      productId: 'p1',
      name: name,
      imagePaths: ['$id.jpg'],
      imageUrls: ['https://x/$id.jpg'],
      position: position,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    Future<_FakeRemote> run(final ProductColorDiff colorDiff) async {
      final remote = _FakeRemote(remoteProduct);
      final result = await buildRepository(remote).updateProduct(
        original: original,
        target: original.copyWith(status: ProductStatus.archived),
        colorDiff: colorDiff,
      );
      expect(result.isSuccess, isTrue);
      return remote;
    }

    test(
      'colour writes run after the product row: delete, release names, update, insert',
      () async {
        final renamed = color('a', '黑', 0);
        final remote = await run(
          ProductColorDiff(
            idsToDelete: const ['gone'],
            toUpdate: [
              ProductColorUpdate(
                original: renamed,
                target: renamed.copyWith(name: '灰'),
              ),
            ],
            toAdd: const [
              NewProductColor(name: '白', imagePaths: ['n.jpg'], position: 1),
            ],
          ),
        );

        expect(remote.writes, [
          'updateProduct',
          'deleteColor:gone',
          'updateColor:a',
          'updateColor:a',
          'insertProductColors',
        ]);
        expect(remote.colorWrites.map((final write) => write.$2), [
          {'name': null},
          {'name': '灰'},
        ]);
      },
    );

    test(
      'swapping two colour names clears both before writing either',
      () async {
        final a = color('a', '黑', 0);
        final b = color('b', '白', 1);
        final remote = await run(
          ProductColorDiff(
            idsToDelete: const [],
            toAdd: const [],
            toUpdate: [
              ProductColorUpdate(
                original: a,
                target: a.copyWith(name: '白'),
              ),
              ProductColorUpdate(
                original: b,
                target: b.copyWith(name: '黑'),
              ),
            ],
          ),
        );

        expect(remote.colorWrites.map((final write) => write.$1), [
          'a',
          'b',
          'a',
          'b',
        ]);
        expect(remote.colorWrites.map((final write) => write.$2), [
          {'name': null},
          {'name': null},
          {'name': '白'},
          {'name': '黑'},
        ]);
      },
    );

    test('a position-only change sends only position', () async {
      final a = color('a', '黑', 1);
      final remote = await run(
        ProductColorDiff(
          idsToDelete: const [],
          toAdd: const [],
          toUpdate: [
            ProductColorUpdate(original: a, target: a.copyWith(position: 0)),
          ],
        ),
      );

      expect(remote.colorWrites.single.$1, 'a');
      expect(remote.colorWrites.single.$2, {'position': 0});
    });

    test('added colours are inserted with their positions', () async {
      final remote = await run(
        const ProductColorDiff(
          idsToDelete: [],
          toUpdate: [],
          toAdd: [
            NewProductColor(name: '黑', imagePaths: ['a.jpg'], position: 2),
            NewProductColor(name: '白', imagePaths: ['b.jpg'], position: 3),
          ],
        ),
      );

      expect(remote.insertedColors!.map((final c) => c.position), [2, 3]);
      expect(remote.insertedColors!.map((final c) => c.toJson()['name']), [
        '黑',
        '白',
      ]);
    });
  });
}
