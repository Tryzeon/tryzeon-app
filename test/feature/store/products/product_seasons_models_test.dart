import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/personal/shop/data/models/shop_product_collection.dart';
import 'package:tryzeon/feature/personal/shop/data/models/shop_product_model.dart';
import 'package:tryzeon/feature/personal/shop/data/models/shop_store_info_model.dart';
import 'package:tryzeon/feature/store/products/data/collections/product_collection.dart';
import 'package:tryzeon/feature/store/products/data/models/create_product_request.dart';
import 'package:tryzeon/feature/store/products/data/models/product_model.dart';

void main() {
  test('stores seasons across request, models, and collections', () {
    final seasons = ['spring', 'winter'];
    final timestamp = DateTime(2026, 4, 25);

    final request = CreateProductRequest(
      storeId: 'store-1',
      name: 'Linen Shirt',
      categoryIds: const ['tops'],
      price: 1200,
      imagePaths: const ['path-1'],
      seasons: seasons,
    );
    final productModel = ProductModel(
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
    final shopProductModel = ShopProductModel(
      storeInfo: const ShopStoreInfoModel(id: 'store-1', name: 'Season Shop'),
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
    final productCollection = ProductCollection()..seasons = seasons;
    final shopProductCollection = ShopProductCollection()..seasons = seasons;

    expect(request.toJson()['seasons'], seasons);
    expect(productModel.seasons, seasons);
    expect(shopProductModel.seasons, seasons);
    expect(productCollection.seasons, seasons);
    expect(shopProductCollection.seasons, seasons);
  });
}
