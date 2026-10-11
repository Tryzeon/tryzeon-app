import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';

part 'list_shop_products_request.g.dart';

@JsonSerializable(createFactory: false)
class ListShopProductsRequest {
  const ListShopProductsRequest({
    required this.sortColumn,
    required this.sortAscending,
    required this.limit,
    required this.offset,
    this.storeId,
    this.searchQuery,
    this.categoryIds,
    this.minPrice,
    this.maxPrice,
    this.channels,
    this.gender,
    this.materials,
    this.elasticities,
    this.fits,
    this.thicknesses,
    this.styles,
    this.seasons,
    this.userLatitude,
    this.userLongitude,
  });

  @JsonKey(name: 'p_store_id')
  final String? storeId;
  @JsonKey(name: 'p_search_query')
  final String? searchQuery;
  @JsonKey(name: 'p_category_ids')
  final List<String>? categoryIds;
  @JsonKey(name: 'p_min_price')
  final int? minPrice;
  @JsonKey(name: 'p_max_price')
  final int? maxPrice;
  @JsonKey(name: 'p_channels')
  final List<StoreChannel>? channels;
  @JsonKey(name: 'p_gender')
  final ProductGender? gender;
  @JsonKey(name: 'p_materials')
  final List<String>? materials;
  @JsonKey(name: 'p_elasticities')
  final List<ProductElasticity>? elasticities;
  @JsonKey(name: 'p_fits')
  final List<ProductFit>? fits;
  @JsonKey(name: 'p_thicknesses')
  final List<ProductThickness>? thicknesses;
  @JsonKey(name: 'p_styles')
  final List<ClothingStyle>? styles;
  @JsonKey(name: 'p_seasons')
  final List<ProductSeason>? seasons;
  @JsonKey(name: 'p_sort_column')
  final String sortColumn;
  @JsonKey(name: 'p_sort_ascending')
  final bool sortAscending;
  @JsonKey(name: 'p_user_lat')
  final double? userLatitude;
  @JsonKey(name: 'p_user_lng')
  final double? userLongitude;
  @JsonKey(name: 'p_limit')
  final int limit;
  @JsonKey(name: 'p_offset')
  final int offset;

  Map<String, dynamic> toJson() => _$ListShopProductsRequestToJson(this);
}
