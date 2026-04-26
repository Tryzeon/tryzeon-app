import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/personal/data/mappers/personal_mappr.dart';
import 'package:tryzeon/feature/personal/shop/data/models/shop_product_model.dart';
import 'package:tryzeon/feature/personal/shop/data/models/shop_store_info_model.dart';
import 'package:tryzeon/feature/store/data/mappers/store_mappr.dart';
import 'package:tryzeon/feature/store/products/data/models/product_model.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_attributes.dart';

void main() {
  test('maps seasons at the model and entity boundary', () {
    final timestamp = DateTime(2026, 4, 25);
    final productModel = ProductModel(
      storeId: 'store-1',
      name: 'Linen Shirt',
      categoryIds: const ['tops'],
      price: 1200,
      imagePaths: const ['path-1'],
      imageUrls: const ['url-1'],
      id: 'product-1',
      seasons: const ['spring', 'winter'],
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    final product = Product(
      storeId: 'store-1',
      name: 'Linen Shirt',
      categoryIds: const ['tops'],
      price: 1200,
      imagePaths: const ['path-1'],
      imageUrls: const ['url-1'],
      id: 'product-1',
      seasons: const [ProductSeason.spring, ProductSeason.winter],
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    final shopProductModel = ShopProductModel(
      storeInfo: const ShopStoreInfoModel(id: 'store-1', name: 'Season Shop'),
      name: 'Linen Shirt',
      categoryIds: const ['tops'],
      price: 1200,
      imagePaths: const ['path-1'],
      imageUrls: const ['url-1'],
      id: 'product-1',
      seasons: const ['summer'],
      createdAt: timestamp,
      updatedAt: timestamp,
    );

    expect(StoreMapprHelper.stringsToSeasons(productModel), [
      ProductSeason.spring,
      ProductSeason.winter,
    ]);
    expect(StoreMapprHelper.seasonsToStrings(product), ['spring', 'winter']);
    expect(ShopProductMapprHelper.seasonsFromStrings(shopProductModel), [
      ProductSeason.summer,
    ]);
  });
}
