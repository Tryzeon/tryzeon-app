import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/feature/common/product_categories/data/collections/product_category_collection.dart';
import 'package:tryzeon/feature/common/product_categories/data/mappers/product_category_mappr.dart';
import 'package:tryzeon/feature/common/product_categories/data/models/product_category_model.dart';

class ProductCategoryLocalDataSource {
  ProductCategoryLocalDataSource(this._isarService, this._cacheEntryLocalDataSource);
  final IsarService _isarService;
  final CacheEntryLocalDataSource _cacheEntryLocalDataSource;
  static const _mappr = ProductCategoryMappr();
  static const cacheKey = 'product_categories';

  Future<CacheLookup<List<ProductCategoryModel>>> getProductCategories() async {
    final isar = await _isarService.db;
    final cacheStatus = await _cacheEntryLocalDataSource.getEntryStatus(cacheKey);
    if (cacheStatus == null) return const CacheMiss();

    if (cacheStatus == CacheEntryStatus.empty) {
      return const CacheEmpty();
    }

    final collections = await isar.productCategoryCollections.where().findAll();
    if (collections.isEmpty) return const CacheMiss();

    final models = _mappr.convertList<ProductCategoryCollection, ProductCategoryModel>(
      collections,
    );
    return CacheHit(models);
  }

  Future<void> saveProductCategories(final List<ProductCategoryModel> categories) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.productCategoryCollections.clear();
      final collections = _mappr
          .convertList<ProductCategoryModel, ProductCategoryCollection>(categories)
          .toList();
      await isar.productCategoryCollections.putAll(collections);
    });
    await _cacheEntryLocalDataSource.markListState(cacheKey, isEmpty: categories.isEmpty);
  }
}
