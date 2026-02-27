import 'package:equatable/equatable.dart';
import 'package:tryzeon/core/modules/location/domain/entities/user_location.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/product_sort_option.dart';

class ShopFilter extends Equatable {
  const ShopFilter({
    this.storeId,
    this.searchQuery,
    this.sortOption = ProductSortOption.latest,
    this.minPrice,
    this.maxPrice,
    this.categories,
    this.userLocation,
  });

  final String? storeId;
  final String? searchQuery;
  final ProductSortOption sortOption;
  final int? minPrice;
  final int? maxPrice;
  final Set<String>? categories;

  /// 使用者位置（用於附近店家排序）
  final UserLocation? userLocation;

  @override
  List<Object?> get props => [
    storeId,
    searchQuery,
    sortOption,
    minPrice,
    maxPrice,
    categories,
    userLocation,
  ];
}
