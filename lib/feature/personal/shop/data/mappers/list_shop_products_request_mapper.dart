import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/personal/shop/data/dtos/list_shop_products_request.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_filter.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_sort.dart';

/// Empty filter groups and an all-channels selection are sent as null, which
/// the RPC reads as "no filter".
ListShopProductsRequest toListShopProductsRequest(
  final ShopFilter filter, {
  required final int limit,
  required final int offset,
}) {
  final (column, ascending) = switch (filter.sort) {
    ShopSortLatest() => (ShopSortColumn.createdAt, false),
    ShopSortPriceLowToHigh() => (ShopSortColumn.price, true),
    ShopSortPriceHighToLow() => (ShopSortColumn.price, false),
    ShopSortProximity() => (ShopSortColumn.proximity, true),
  };
  final (latitude, longitude) = switch (filter.sort) {
    ShopSortProximity(:final latitude, :final longitude) => (
      latitude,
      longitude,
    ),
    _ => (null, null),
  };
  final searchQuery = filter.searchQuery;
  final channels = filter.channels;

  return ListShopProductsRequest(
    storeId: filter.storeId,
    searchQuery: searchQuery == null || searchQuery.isEmpty
        ? null
        : searchQuery,
    categoryIds: _nonEmpty(filter.categories),
    minPrice: filter.minPrice,
    maxPrice: filter.maxPrice,
    channels:
        channels == null ||
            channels.isEmpty ||
            channels.length == StoreChannel.values.length
        ? null
        : StoreChannel.listFromSet(channels),
    gender: filter.gender,
    materials: _nonEmpty(filter.materials),
    elasticities: _nonEmpty(filter.elasticities),
    fits: _nonEmpty(filter.fits),
    thicknesses: _nonEmpty(filter.thicknesses),
    styles: _nonEmpty(filter.styles),
    seasons: _nonEmpty(filter.seasons),
    sortColumn: column,
    sortAscending: ascending,
    userLatitude: latitude,
    userLongitude: longitude,
    limit: limit,
    offset: offset,
  );
}

List<T>? _nonEmpty<T>(final Iterable<T>? values) =>
    values == null || values.isEmpty ? null : values.toList();
