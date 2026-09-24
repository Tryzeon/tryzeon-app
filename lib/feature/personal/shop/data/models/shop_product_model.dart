import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_size/data/models/product_size_model.dart';
import 'package:tryzeon/feature/personal/shop/data/models/shop_store_info_model.dart';

part 'shop_product_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ShopProductModel {
  const ShopProductModel({
    required this.storeInfo,
    required this.name,
    required this.categoryId,
    required this.garmentType,
    required this.price,
    required this.imagePaths,
    required this.imageUrls,
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.purchaseLink,
    this.description,
    this.material,
    this.elasticity,
    this.fit,
    this.thickness,
    this.styles,
    this.seasons,
    this.sizes,
  });

  factory ShopProductModel.fromJson(final Map<String, dynamic> json) =>
      _$ShopProductModelFromJson(json);

  @JsonKey(name: 'store_profiles', includeToJson: false)
  final ShopStoreInfoModel storeInfo;
  final String name;
  final String categoryId;
  @JsonKey(unknownEnumValue: GarmentType.others)
  final GarmentType garmentType;
  final double price;
  final List<String> imagePaths;
  @JsonKey(includeToJson: false)
  final List<String> imageUrls;
  final String id;
  final String? purchaseLink;
  final String? description;
  final String? material;
  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  final ProductElasticity? elasticity;
  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  final ProductFit? fit;
  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  final ProductThickness? thickness;
  @JsonKey(fromJson: _stylesFromJson)
  final List<ClothingStyle>? styles;
  @JsonKey(fromJson: _seasonsFromJson)
  final List<ProductSeason>? seasons;
  @JsonKey(name: 'product_sizes', includeToJson: false)
  final List<ProductSizeModel>? sizes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => _$ShopProductModelToJson(this);
}

List<ClothingStyle>? _stylesFromJson(final List<dynamic>? json) =>
    ClothingStyle.listFromStrings(json?.whereType<String>());

List<ProductSeason>? _seasonsFromJson(final List<dynamic>? json) =>
    ProductSeason.listFromStrings(json?.whereType<String>());
