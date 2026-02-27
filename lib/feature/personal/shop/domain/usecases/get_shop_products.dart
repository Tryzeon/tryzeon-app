import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/location/domain/entities/user_location.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/product_sort_option.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/repositories/product_repository.dart';
import 'package:typed_result/typed_result.dart';

class GetShopProducts {
  GetShopProducts(this._repository);
  final ProductRepository _repository;

  Future<Result<List<ShopProduct>, Failure>> call({
    final String? storeId,
    final String? searchQuery,
    final ProductSortOption sortOption = ProductSortOption.latest,
    final int? minPrice,
    final int? maxPrice,
    final Set<String>? categories,
    final UserLocation? userLocation,
    final bool forceRefresh = false,
  }) {
    return _repository.getProducts(
      storeId: storeId,
      searchQuery: searchQuery,
      sortOption: sortOption,
      minPrice: minPrice,
      maxPrice: maxPrice,
      categories: categories,
      userLocation: userLocation,
      forceRefresh: forceRefresh,
    );
  }
}
