import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/feature/common/product_categories/data/collections/product_category_collection.dart';
import 'package:tryzeon/feature/common/product_categories/data/mappers/product_category_mappr.dart';
import 'package:tryzeon/feature/common/product_categories/data/models/product_category_model.dart';

class ProductCategoryLocalDataSource {
  ProductCategoryLocalDataSource(this._isarService);
  final IsarService _isarService;
  static const _mappr = ProductCategoryMappr();

  Future<List<ProductCategoryModel>?> getProductCategories() async {
    final isar = await _isarService.db;
    final collections = await isar.productCategoryCollections.where().findAll();
    if (collections.isEmpty) return null;

    if (collections.first.lastUpdated == null ||
        DateTime.now().difference(collections.first.lastUpdated!) >
            AppConstants.staleDurationProductCategories) {
      return null;
    }

    final models = _mappr.convertList<ProductCategoryCollection, ProductCategoryModel>(
      collections,
    );
    return models;
  }

  Future<void> saveProductCategories(final List<ProductCategoryModel> categories) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.productCategoryCollections.clear();
      final now = DateTime.now();
      final collections = _mappr
          .convertList<ProductCategoryModel, ProductCategoryCollection>(categories)
          .map((final e) => e..lastUpdated = now)
          .toList();
      await isar.productCategoryCollections.putAll(collections);
    });
  }
}
