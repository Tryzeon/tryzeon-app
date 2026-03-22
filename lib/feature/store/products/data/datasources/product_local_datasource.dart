import 'dart:typed_data';

import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/core/domain/services/cache_service.dart';
import 'package:tryzeon/feature/store/data/mappers/store_mappr.dart';
import 'package:tryzeon/feature/store/products/data/collections/product_collection.dart';
import 'package:tryzeon/feature/store/products/data/models/product_model.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_sort_condition.dart';

class ProductLocalDataSource {
  ProductLocalDataSource(this._isarService, this._cacheService);
  final IsarService _isarService;
  final CacheService _cacheService;
  static const _mappr = StoreMappr();

  Future<List<ProductModel>?> getProducts({required final SortCondition sort}) async {
    final isar = await _isarService.db;

    // 檢查是否有資料
    if (await isar.productCollections.count() == 0) return null;

    final q = isar.productCollections.where();
    List<ProductCollection> collections;

    switch (sort.field) {
      case SortField.name:
        collections = await (sort.ascending ? q.sortByName() : q.sortByNameDesc())
            .findAll();
        break;
      case SortField.price:
        collections = await (sort.ascending ? q.sortByPrice() : q.sortByPriceDesc())
            .findAll();
        break;
      case SortField.createdAt:
        collections =
            await (sort.ascending ? q.sortByCreatedAt() : q.sortByCreatedAtDesc())
                .findAll();
        break;
      case SortField.updatedAt:
        collections =
            await (sort.ascending ? q.sortByUpdatedAt() : q.sortByUpdatedAtDesc())
                .findAll();
        break;
    }

    final models = _mappr.convertList<ProductCollection, ProductModel>(collections);
    return models;
  }

  Future<void> saveProducts(final List<ProductModel> models) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.productCollections.clear();
      final collections = _mappr.convertList<ProductModel, ProductCollection>(models);

      await isar.productCollections.putAll(collections);
    });
  }

  Future<void> saveProductImage(final Uint8List bytes, final String path) async {
    await _cacheService.saveImage(bytes, path);
  }

  Future<void> deleteProductImages(final List<String> paths) async {
    await _cacheService.deleteImages(paths);
  }
}
