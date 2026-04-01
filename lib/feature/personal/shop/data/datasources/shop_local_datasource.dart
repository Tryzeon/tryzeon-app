import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/feature/personal/shop/data/models/shop_product_collection.dart';
import 'package:tryzeon/feature/personal/shop/data/models/shop_product_model.dart';
import 'package:tryzeon/feature/personal/shop/data/models/shop_store_info_model.dart';

class ShopLocalDataSource {
  ShopLocalDataSource(this._isarService, this._cacheEntryLocalDataSource);

  final IsarService _isarService;
  final CacheEntryLocalDataSource _cacheEntryLocalDataSource;

  static String productCacheKey(final String productId) => 'shop_product:$productId';

  Future<void> saveProducts(final List<ShopProductModel> products) async {
    final isar = await _isarService.db;

    final collections = products.map((final model) {
      final storeInfo = ShopStoreInfoEmbedded()
        ..storeId = model.storeInfo.id
        ..name = model.storeInfo.name
        ..address = model.storeInfo.address
        ..logoUrl = model.storeInfo.logoUrl;

      return ShopProductCollection()
        ..productId = model.id
        ..name = model.name
        ..price = model.price
        ..categoryIds = model.categoryIds
        ..imagePaths = model.imagePaths
        ..imageUrls = model.imageUrls
        ..purchaseLink = model.purchaseLink
        ..material = model.material
        ..elasticity = model.elasticity
        ..fit = model.fit
        ..styles = model.styles
        ..createdAt = model.createdAt
        ..updatedAt = model.updatedAt
        ..storeInfo = storeInfo;
    }).toList();

    await isar.writeTxn(() async {
      await isar.shopProductCollections.putAll(collections);
    });

    for (final product in products) {
      await _cacheEntryLocalDataSource.markHasData(productCacheKey(product.id));
    }
  }

  Future<void> saveProduct(final ShopProductModel product) async {
    await saveProducts([product]);
  }

  Future<CacheLookup<ShopProductModel>> getProductById(final String productId) async {
    final isar = await _isarService.db;
    final cacheStatus = await _cacheEntryLocalDataSource.getEntryStatus(
      productCacheKey(productId),
    );
    if (cacheStatus == null) return const CacheMiss();

    final collection = await isar.shopProductCollections.getByProductId(productId);

    if (collection == null) return const CacheMiss();

    final storeInfoModel = ShopStoreInfoModel(
      id: collection.storeInfo.storeId,
      name: collection.storeInfo.name,
      address: collection.storeInfo.address,
      logoUrl: collection.storeInfo.logoUrl,
    );

    return CacheHit(
      ShopProductModel(
        storeInfo: storeInfoModel,
        name: collection.name,
        categoryIds: collection.categoryIds,
        price: collection.price,
        imagePaths: collection.imagePaths,
        imageUrls: collection.imageUrls,
        id: collection.productId,
        purchaseLink: collection.purchaseLink,
        material: collection.material,
        elasticity: collection.elasticity,
        fit: collection.fit,
        styles: collection.styles,
        createdAt: collection.createdAt,
        updatedAt: collection.updatedAt,
        sizes: null,
      ),
    );
  }
}
