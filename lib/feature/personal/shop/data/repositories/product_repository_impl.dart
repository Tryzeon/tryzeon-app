import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/shop/data/datasources/shop_remote_datasource.dart';
import 'package:tryzeon/feature/personal/shop/data/dtos/shop_product_dto.dart';
import 'package:tryzeon/feature/personal/shop/data/dtos/shop_store_info_dto.dart';
import 'package:tryzeon/feature/personal/shop/data/mappers/list_shop_products_request_mapper.dart';
import 'package:tryzeon/feature/personal/shop/data/mappers/shop_mappr.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_filter.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:tryzeon/feature/personal/shop/domain/repositories/product_repository.dart';
import 'package:typed_result/typed_result.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl({required final ShopRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final ShopRemoteDataSource _remoteDataSource;
  static const _mappr = ShopMappr();

  @override
  Future<Result<List<ShopProduct>, Failure>> listProducts(
    final ShopFilter filter, {
    required final int limit,
    required final int offset,
  }) async {
    try {
      final result = await _remoteDataSource.listProducts(
        toListShopProductsRequest(filter, limit: limit, offset: offset),
      );

      return Ok(_mappr.convertList<ShopProductDto, ShopProduct>(result));
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get product list', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<ShopProduct, Failure>> getProduct(
    final String productId,
  ) async {
    try {
      final model = await _remoteDataSource.getProduct(productId);
      return Ok(_mappr.convert<ShopProductDto, ShopProduct>(model));
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get product by id $productId', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<ShopStoreInfo, Failure>> getStoreInfo(
    final String storeId,
  ) async {
    try {
      return Ok(
        _mappr.convert<ShopStoreInfoDto, ShopStoreInfo>(
          await _remoteDataSource.getStoreProfile(storeId),
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch store info for $storeId', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
