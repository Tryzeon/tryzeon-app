import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/location/domain/entities/user_location.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/product_sort_option.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:typed_result/typed_result.dart';

/// Repository for product query operations.
abstract class ProductRepository {
  /// Fetches a list of products based on the provided filters.
  Future<Result<List<ShopProduct>, Failure>> getProducts({
    final ProductSortOption sortOption = ProductSortOption.latest,
    final String? searchQuery,
    final int? minPrice,
    final int? maxPrice,
    final Set<String>? categories,
    final UserLocation? userLocation,
    final bool forceRefresh = false,
  });
}
