import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_filter.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_sort.dart';

part 'shop_filter_provider.g.dart';

@riverpod
class ShopFilterNotifier extends _$ShopFilterNotifier {
  @override
  ShopFilter build() => const ShopFilter();

  void setSearch(final String? query) =>
      _update(state.copyWith(searchQuery: query));

  void setSort(final ShopSort sort) => _update(state.copyWith(sort: sort));

  void setPriceRange({final int? min, final int? max}) =>
      _update(state.copyWith(minPrice: min, maxPrice: max));

  void setChannels(final Set<StoreChannel>? channels) =>
      _update(state.copyWith(channels: channels));

  void setMaterials(final Set<String>? materials) =>
      _update(state.copyWith(materials: materials));

  void setElasticities(final Set<ProductElasticity>? elasticities) =>
      _update(state.copyWith(elasticities: elasticities));

  void setFits(final Set<ProductFit>? fits) =>
      _update(state.copyWith(fits: fits));

  void setThicknesses(final Set<ProductThickness>? thicknesses) =>
      _update(state.copyWith(thicknesses: thicknesses));

  void setStyles(final Set<ClothingStyle>? styles) =>
      _update(state.copyWith(styles: styles));

  void setSeasons(final Set<ProductSeason>? seasons) =>
      _update(state.copyWith(seasons: seasons));

  void setCategories(final Set<String> categoryIds) =>
      _update(state.copyWith(categories: categoryIds));

  void setGender(final ProductGender? gender) =>
      _update(state.copyWith(gender: gender, categories: null));

  void _update(final ShopFilter next) => state = next.normalized();
}
