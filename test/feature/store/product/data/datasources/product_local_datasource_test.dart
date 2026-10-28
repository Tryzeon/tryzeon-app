import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/core/utils/public_image_url.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/store/product/data/collections/product_cache.dart';
import 'package:tryzeon/feature/store/product/data/datasources/product_local_datasource.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';

import '../../../../../support/isar_test_harness.dart';

void main() {
  late TestIsar harness;

  setUp(() async {
    harness = await openTestIsar();
  });

  tearDown(() async {
    await harness.dispose();
  });

  ProductLocalDataSource build() => ProductLocalDataSource(
    harness.service,
    CacheEntryLocalDataSource(harness.service),
  );

  final product = Product(
    id: 'p1',
    storeId: 's1',
    name: 'Linen shirt',
    categoryId: 'c1',
    garmentType: GarmentType.top,
    price: 1280,
    colors: [
      ProductColor(
        id: 'k1',
        productId: 'p1',
        name: '米白',
        imagePaths: const ['p1/a.jpg', 'p1/b.jpg'],
        imageUrls: [
          PublicImageUrl.of('p1/a.jpg'),
          PublicImageUrl.of('p1/b.jpg'),
        ],
        position: 0,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
      ProductColor(
        id: 'k2',
        productId: 'p1',
        imagePaths: const ['p1/c.jpg'],
        imageUrls: [PublicImageUrl.of('p1/c.jpg')],
        position: 1,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    ],
    status: ProductStatus.archived,
    gender: ProductGender.female,
    purchaseLink: 'https://shop/p1',
    description: 'Breathable',
    material: 'Linen',
    elasticity: ProductElasticity.low,
    fit: ProductFit.loose,
    thickness: ProductThickness.medium,
    styles: {ClothingStyle.basic, ClothingStyle.natural},
    seasons: {ProductSeason.summer, ProductSeason.spring},
    sizes: [
      ProductSize(
        id: 'z1',
        productId: 'p1',
        name: 'M',
        garmentMeasurements: const GarmentMeasurements(
          shoulderWidth: 42,
          chestCircumference: 104,
          length: 70,
        ),
        bodyMeasurementRanges: const BodyMeasurementRanges(
          height: MeasurementRange(min: 160, max: 172),
          chest: MeasurementRange(min: 86, max: 94),
        ),
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    ],
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026, 6),
  );

  test('saveProduct reads back exactly the product it saved', () async {
    final local = build();
    await local.saveProducts('s1', const []);

    await local.saveProduct(product);

    expect(
      (await local.listProducts(storeId: 's1') as CacheHit<List<Product>>).data,
      [product],
    );
  });

  test('listProducts reads back exactly the products it saved', () async {
    final local = build();

    await local.saveProducts('s1', [product]);

    expect(
      (await local.listProducts(storeId: 's1') as CacheHit<List<Product>>).data,
      [product],
    );
  });

  test('styles and seasons are cached in declaration order', () async {
    await build().saveProduct(product);

    final cached = await harness.isar.productCaches.getByProductId('p1');

    expect(cached!.styles, ['basic', 'natural']);
    expect(cached.seasons, ['spring', 'summer']);
  });

  group('store list entry', () {
    CacheEntryLocalDataSource entries() =>
        CacheEntryLocalDataSource(harness.service);
    final storeKey = ProductLocalDataSource.cacheKeyForStore('s1');

    test('saveProduct leaves an absent list entry absent', () async {
      await build().saveProduct(product);

      expect(await entries().getEntryStatus(storeKey), isNull);
    });

    test('saveProduct keeps a cached list complete', () async {
      final local = build();
      await local.saveProducts('s1', [product]);
      final other = product.copyWith(id: 'p2', name: 'Wool coat');

      await local.saveProduct(other);

      expect(
        await entries().getEntryStatus(storeKey),
        CacheEntryStatus.hasData,
      );
      final listed =
          (await local.listProducts(storeId: 's1') as CacheHit<List<Product>>)
              .data;
      expect(listed.map((final p) => p.id), unorderedEquals(['p1', 'p2']));
    });

    test('deleteProduct leaves an absent list entry absent', () async {
      await build().deleteProduct(storeId: 's1', productId: 'p1');

      expect(await entries().getEntryStatus(storeKey), isNull);
    });
  });
}
