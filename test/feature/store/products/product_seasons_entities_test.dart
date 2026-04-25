import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/image_item.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_attributes.dart';

void main() {
  test('preserves seasons across product entities', () {
    final seasons = [ProductSeason.spring, ProductSeason.winter];
    final timestamp = DateTime(2026, 4, 25);

    final createParams = CreateProductParams(
      storeId: 'store-1',
      name: 'Linen Shirt',
      categoryIds: const ['tops'],
      price: 1200,
      images: const [],
      seasons: seasons,
    );
    final updateParams = UpdateProductParams(
      productId: 'product-1',
      finalImageOrder: const <ImageItem>[],
      sizesToAdd: const [],
      sizesToUpdate: const [],
      sizeIdsToDelete: const [],
      name: 'Linen Shirt',
      categoryIds: const ['tops'],
      price: 1200,
      seasons: seasons,
    );
    final product = Product(
      storeId: 'store-1',
      name: 'Linen Shirt',
      categoryIds: const ['tops'],
      price: 1200,
      imagePaths: const ['path-1'],
      imageUrls: const ['url-1'],
      id: 'product-1',
      seasons: seasons,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    final shopProduct = ShopProduct(
      storeInfo: const ShopStoreInfo(
        id: 'store-1',
        name: 'Season Shop',
        address: 'Taipei',
      ),
      name: 'Linen Shirt',
      categoryIds: const ['tops'],
      price: 1200,
      imagePaths: const ['path-1'],
      imageUrls: const ['url-1'],
      id: 'product-1',
      seasons: seasons,
      createdAt: timestamp,
      updatedAt: timestamp,
    );

    expect(createParams.seasons, seasons);
    expect(updateParams.seasons, seasons);
    expect(product.seasons, seasons);
    expect(shopProduct.seasons, seasons);
  });
}
