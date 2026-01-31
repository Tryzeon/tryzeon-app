import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/common/product_categories/data/datasources/product_category_local_datasource.dart';
import 'package:tryzeon/feature/common/product_categories/data/datasources/product_category_remote_datasource.dart';
import 'package:tryzeon/feature/common/product_categories/domain/entities/product_category.dart';
import 'package:tryzeon/feature/common/product_categories/domain/repositories/product_category_repository.dart';
import 'package:typed_result/typed_result.dart';

class ProductCategoryRepositoryImpl implements ProductCategoryRepository {
  ProductCategoryRepositoryImpl(this._remoteDataSource, this._localDataSource);
  final ProductCategoryRemoteDataSource _remoteDataSource;
  final ProductCategoryLocalDataSource _localDataSource;

  @override
  Future<Result<List<ProductCategory>, Failure>> getProductCategories({
    final bool forceRefresh = false,
  }) async {
    // 1. Try Local Cache
    if (!forceRefresh) {
      try {
        final cachedCategories = await _localDataSource.getProductCategories();
        if (cachedCategories != null) return Ok(cachedCategories);
      } catch (e, stackTrace) {
        AppLogger.warning(
          'Local cache read failed, falling back to remote',
          e,
          stackTrace,
        );
      }
    }

    // 2. Fetch from API
    try {
      final remoteCategories = await _remoteDataSource.getProductCategories();

      // 3. Update Cache
      try {
        await _localDataSource.saveProductCategories(remoteCategories);
      } catch (e, stackTrace) {
        AppLogger.warning('Failed to save product categories to cache', e, stackTrace);
      }

      return Ok(remoteCategories);
    } catch (e, stackTrace) {
      AppLogger.error('商品類型獲取失敗', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
