import 'dart:typed_data';

import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/core/domain/services/cache_service.dart';
import 'package:tryzeon/feature/store/data/mappers/store_mappr.dart';
import 'package:tryzeon/feature/store/products/data/collections/product_collection.dart';
import 'package:tryzeon/feature/store/products/data/models/product_model.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_sort_condition.dart';

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

  Future<ProductModel?> getProductById(final String productId) async {
    final isar = await _isarService.db;
    final collection = await isar.productCollections.getByProductId(productId);
    if (collection == null) return null;
    return _mappr.convert<ProductCollection, ProductModel>(collection);
  }

  Future<void> saveProduct(final ProductModel model) async {
    final isar = await _isarService.db;
    final collection = _mappr.convert<ProductModel, ProductCollection>(model);

    await isar.writeTxn(() async {
      await isar.productCollections.putByProductId(collection);
    });
    final cacheKey = cacheKeyForStore(model.storeId);
    await _cacheEntryLocalDataSource.markListState(cacheKey, isEmpty: false);
  }

  Future<CacheLookup<List<ProductModel>>> getProducts({
    required final String storeId,
    required final SortCondition sort,
  }) async {
    final isar = await _isarService.db;
    final cacheKey = cacheKeyForStore(storeId);
    final cacheStatus = await _cacheEntryLocalDataSource.getEntryStatus(cacheKey);
    if (cacheStatus == null) return const CacheMiss();

    if (cacheStatus == CacheEntryStatus.empty) {
      return const CacheEmpty();
    }

    final collections = await isar.productCollections
        .filter()
        .storeIdEqualTo(storeId)
        .findAll();

    if (collections.isEmpty) return const CacheMiss();

    collections.sort((final a, final b) {
      final result = switch (sort.field) {
        SortField.name => a.name.compareTo(b.name),
        SortField.price => a.price.compareTo(b.price),
        SortField.createdAt => _compareNullableDateTime(a.createdAt, b.createdAt),
        SortField.updatedAt => _compareNullableDateTime(a.updatedAt, b.updatedAt),
      };
      return sort.ascending ? result : -result;
    });

    final models = _mappr.convertList<ProductCollection, ProductModel>(collections);
    return CacheHit(models);
  }

  Future<void> saveProducts(final String storeId, final List<ProductModel> models) async {
    final isar = await _isarService.db;
    final existingCollections = await isar.productCollections
        .filter()
        .storeIdEqualTo(storeId)
        .findAll();

    await isar.writeTxn(() async {
      await isar.productCollections.deleteAll(
        existingCollections.map((final e) => e.id).toList(),
      );
      final collections = _mappr.convertList<ProductModel, ProductCollection>(models);

      await isar.productCollections.putAll(collections);
    });

    final cacheKey = cacheKeyForStore(storeId);
    await _cacheEntryLocalDataSource.markListState(cacheKey, isEmpty: models.isEmpty);
  }

  Future<void> deleteProduct({
    required final String storeId,
    required final String productId,
  }) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.productCollections.deleteByProductId(productId);
    });

    final remainingCount = await isar.productCollections
        .filter()
        .storeIdEqualTo(storeId)
        .count();
    final cacheKey = cacheKeyForStore(storeId);
    await _cacheEntryLocalDataSource.markListState(
      cacheKey,
      isEmpty: remainingCount == 0,
    );
  }

  Future<void> saveProductImage(final Uint8List bytes, final String path) async {
    await _cacheService.saveImage(bytes, path);
  }

  Future<void> deleteProductImages(final List<String> paths) async {
    await _cacheService.deleteImages(paths);
  }

  int _compareNullableDateTime(final DateTime? a, final DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    return a.compareTo(b);
  }
}
