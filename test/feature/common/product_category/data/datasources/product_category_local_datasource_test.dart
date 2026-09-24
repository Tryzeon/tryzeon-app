import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_category/data/datasources/product_category_local_datasource.dart';
import 'package:tryzeon/feature/common/product_category/domain/entities/product_category.dart';

import '../../../../../support/isar_test_harness.dart';

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

  test('reads back exactly the entities it saved', () async {
    const categories = [
      ProductCategory(
        id: 'c1',
        code: 'dress',
        name: '洋裝',
        gender: ProductGender.female,
        defaultGarmentType: GarmentType.onePiece,
        imageMaleUrl: 'https://cdn/m.jpg',
        imageFemaleUrl: 'https://cdn/f.jpg',
      ),
      ProductCategory(
        id: 'c2',
        code: 'tee',
        name: 'T 恤',
        defaultGarmentType: GarmentType.top,
      ),
    ];
    final local = ProductCategoryLocalDataSource(
      harness.service,
      CacheEntryLocalDataSource(harness.service),
    );

    await local.saveProductCategories(categories);
    final lookup = await local.getProductCategories();

    expect((lookup as CacheHit<List<ProductCategory>>).data, unorderedEquals(categories));
  });
}
