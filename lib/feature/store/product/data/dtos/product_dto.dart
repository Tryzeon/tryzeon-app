import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_size/data/dtos/product_size_dto.dart';

export 'package:tryzeon/feature/common/product_size/data/dtos/product_size_dto.dart';

part 'product_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ProductDto {
  const ProductDto({
    required this.storeId,
    required this.name,
    required this.categoryId,
    required this.garmentType,
    required this.price,
    required this.imagePaths,
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.status,
    this.gender,
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

  factory ProductDto.fromJson(final Map<String, dynamic> json) =>
      _$ProductDtoFromJson(json);

  final String storeId;
  final String name;
  final String categoryId;
  @JsonKey(unknownEnumValue: GarmentType.others)
  final GarmentType garmentType;
  final double price;
  @JsonKey(defaultValue: <String>[])
  final List<String> imagePaths;
  final String id;
  @JsonKey(unknownEnumValue: ProductStatus.active)
  final ProductStatus? status;
  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  final ProductGender? gender;
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
  final List<ProductSizeDto>? sizes;
  @JsonKey(includeToJson: false)
  final DateTime createdAt;
  @JsonKey(includeToJson: false)
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => _$ProductDtoToJson(this);
}

List<ClothingStyle>? _stylesFromJson(final List<dynamic>? json) =>
    ClothingStyle.listFromStrings(json?.whereType<String>());

List<ProductSeason>? _seasonsFromJson(final List<dynamic>? json) =>
    ProductSeason.listFromStrings(json?.whereType<String>());
