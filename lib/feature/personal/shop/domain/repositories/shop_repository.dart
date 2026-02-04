import 'package:tryzeon/core/domain/entities/user_location.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/enums/product_sort_option.dart';
import 'package:typed_result/typed_result.dart';

abstract class ShopRepository {
  Future<Result<List<ShopProduct>, Failure>> getProducts({
    final ProductSortOption sortOption = ProductSortOption.latest,
    final String? searchQuery,
    final int? minPrice,
    final int? maxPrice,
    final Set<String>? types,
    final UserLocation? userLocation,
    final bool forceRefresh = false,
  });

  Future<Result<void, Failure>> incrementTryonCount({
    required final String productId,
    required final String storeId,
  });

  Future<Result<void, Failure>> incrementPurchaseClickCount({
    required final String productId,
    required final String storeId,
  });

  Future<Result<List<String>, Failure>> getAds({final bool forceRefresh = false});
}
