import 'dart:typed_data';

import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/core/domain/services/cache_service.dart';
import 'package:tryzeon/feature/store/data/mappers/store_mappr.dart';
import 'package:tryzeon/feature/store/product/data/collections/product_cache.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';

class ProductLocalDataSource {
  ProductLocalDataSource(
    this._isarService,
    this._cacheService,
    this._cacheEntryLocalDataSource,
  );

  final IsarService _isarService;
  final CacheService _cacheService;
  final CacheEntryLocalDataSource _cacheEntryLocalDataSource;
  static const _mappr = StoreMappr();
  static String cacheKeyForStore(final String storeId) => 'store_products:$storeId';
  static String cacheKeyForProduct(final String productId) => 'store_product:$productId';

  Future<CacheLookup<Product>> getProductById(final String productId) async {
    final isar = await _isarService.db;
    final cacheStatus = await _cacheEntryLocalDataSource.getEntryStatus(
      cacheKeyForProduct(productId),
    );
    if (cacheStatus == null) return const CacheMiss();

    final collection = await isar.productCaches.getByProductId(productId);
    if (collection == null) return const CacheMiss();

    return CacheHit(_mappr.convert<ProductCache, Product>(collection));
  }

  Future<void> saveProduct(final Product product) async {
    final isar = await _isarService.db;
    final collection = _mappr.convert<Product, ProductCache>(product);

    await isar.writeTxn(() async {
      await isar.productCaches.putByProductId(collection);
    });
    await _cacheEntryLocalDataSource.markListState(
      cacheKeyForStore(product.storeId),
      isEmpty: false,
    );
    await _cacheEntryLocalDataSource.markHasData(cacheKeyForProduct(product.id));
  }

  Future<CacheLookup<List<Product>>> listProducts({required final String storeId}) async {
    final isar = await _isarService.db;
    final cacheKey = cacheKeyForStore(storeId);
    final cacheStatus = await _cacheEntryLocalDataSource.getEntryStatus(cacheKey);
    if (cacheStatus == null) return const CacheMiss();

    if (cacheStatus == CacheEntryStatus.empty) {
      return const CacheEmpty();
    }

    final collections = await isar.productCaches
        .filter()
        .storeIdEqualTo(storeId)
        .findAll();

    if (collections.isEmpty) return const CacheMiss();

    return CacheHit(_mappr.convertList<ProductCache, Product>(collections));
  }

  Future<void> saveProducts(final String storeId, final List<Product> products) async {
    final isar = await _isarService.db;
    final existingCollections = await isar.productCaches
        .filter()
        .storeIdEqualTo(storeId)
        .findAll();

    await isar.writeTxn(() async {
      await isar.productCaches.deleteAll(
        existingCollections.map((final e) => e.id).toList(),
      );
      final collections = _mappr.convertList<Product, ProductCache>(products);

      await isar.productCaches.putAll(collections);
    });

    final cacheKey = cacheKeyForStore(storeId);
    await _cacheEntryLocalDataSource.markListState(cacheKey, isEmpty: products.isEmpty);
  }

  Future<void> deleteProduct({
    required final String storeId,
    required final String productId,
  }) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.productCaches.deleteByProductId(productId);
    });

    final remainingCount = await isar.productCaches
        .filter()
        .storeIdEqualTo(storeId)
        .count();
    await _cacheEntryLocalDataSource.markListState(
      cacheKeyForStore(storeId),
      isEmpty: remainingCount == 0,
    );
  }

  Future<void> saveProductImage(final Uint8List bytes, final String path) async {
    await _cacheService.saveImage(bytes, path);
  }

  Future<void> deleteProductImages(final List<String> paths) async {
    await _cacheService.deleteImages(paths);
  }
}
