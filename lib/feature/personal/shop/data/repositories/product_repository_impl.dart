import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/location/domain/entities/user_location.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/data/mappers/personal_mappr.dart';
import 'package:tryzeon/feature/personal/shop/data/datasources/shop_remote_datasource.dart';
import 'package:tryzeon/feature/personal/shop/data/models/shop_product_model.dart';
import 'package:tryzeon/feature/personal/shop/data/models/shop_store_info_model.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/product_sort_option.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:tryzeon/feature/personal/shop/domain/repositories/product_repository.dart';
import 'package:typed_result/typed_result.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl({required final ShopRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final ShopRemoteDataSource _remoteDataSource;
  static const _mappr = PersonalMappr();

  @override
  Future<Result<List<ShopProduct>, Failure>> getProducts({
    final String? storeId,
    final String? searchQuery,
    final ProductSortOption sortOption = ProductSortOption.latest,
    final int? minPrice,
    final int? maxPrice,
    final Set<String>? categories,
    final UserLocation? userLocation,
    final bool forceRefresh = false,
  }) async {
    try {
      final result = await _remoteDataSource.getProducts(
        storeId: storeId,
        searchQuery: searchQuery,
        sortOption: sortOption,
        minPrice: minPrice,
        maxPrice: maxPrice,
        categories: categories,
        userLocation: userLocation,
      );
      final products = _mappr.convertList<ShopProductModel, ShopProduct>(result);
      return Ok(products);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get product list', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<ShopStoreInfo, Failure>> getStoreInfo(final String storeId) async {
    try {
      final responseMap = await _remoteDataSource.getStoreProfile(storeId);
      final model = ShopStoreInfoModel.fromJson(responseMap);
      final entity = _mappr.convert<ShopStoreInfoModel, ShopStoreInfo>(model);
      return Ok(entity);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch store info for $storeId', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
