import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/personal/shop/data/dtos/list_shop_products_request.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_filter.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_sort.dart';

/// An all-channels selection is sent as null, which the RPC reads as "no
/// filter" just like an empty group.
ListShopProductsRequest toListShopProductsRequest(
  final ShopFilter filter, {
  required final int limit,
  required final int offset,
}) {
  final normalized = filter.normalized();
  final (column, ascending) = switch (normalized.sort) {
    ShopSortLatest() => (ShopSortColumn.createdAt, false),
    ShopSortPriceLowToHigh() => (ShopSortColumn.price, true),
    ShopSortPriceHighToLow() => (ShopSortColumn.price, false),
    ShopSortProximity() => (ShopSortColumn.proximity, true),
  };
  final (latitude, longitude) = switch (normalized.sort) {
    ShopSortProximity(:final latitude, :final longitude) => (
      latitude,
      longitude,
    ),
    _ => (null, null),
  };
  final channels = normalized.channels;

  return ListShopProductsRequest(
    storeId: normalized.storeId,
    searchQuery: normalized.searchQuery,
    categoryIds: normalized.categories?.toList(),
    minPrice: normalized.minPrice,
    maxPrice: normalized.maxPrice,
    channels: channels == null || channels.length == StoreChannel.values.length
        ? null
        : StoreChannel.listFromSet(channels),
    gender: normalized.gender,
    materials: normalized.materials?.toList(),
    elasticities: normalized.elasticities?.toList(),
    fits: normalized.fits?.toList(),
    thicknesses: normalized.thicknesses?.toList(),
    styles: normalized.styles?.toList(),
    seasons: normalized.seasons?.toList(),
    sortColumn: column,
    sortAscending: ascending,
    userLatitude: latitude,
    userLongitude: longitude,
    limit: limit,
    offset: offset,
  );
}
