import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_filter.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:typed_result/typed_result.dart';

abstract class ProductRepository {
  Future<Result<List<ShopProduct>, Failure>> listProducts(
    final ShopFilter filter, {
    required final int limit,
    required final int offset,
  });

  Future<Result<ShopProduct, Failure>> getProduct(final String productId);

  Future<Result<ShopStoreInfo, Failure>> getStoreInfo(final String storeId);
}
