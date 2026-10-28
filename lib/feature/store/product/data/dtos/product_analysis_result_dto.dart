import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';

part 'product_analysis_result_dto.g.dart';

@JsonSerializable(createToJson: false, checked: true)
class ProductAnalysisResultDto {
  const ProductAnalysisResultDto({
    required this.styles,
    required this.seasons,
    this.name,
    this.color,
    this.categoryId,
    this.gender,
    this.material,
    this.fit,
    this.thickness,
    this.elasticity,
  });

  factory ProductAnalysisResultDto.fromJson(final Map<String, dynamic> json) =>
      _$ProductAnalysisResultDtoFromJson(json);

  final String? name;
  final String? color;
  final String? categoryId;
  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  final ProductGender? gender;
  @JsonKey(fromJson: _stylesFromJson)
  final List<ClothingStyle> styles;
  @JsonKey(fromJson: _seasonsFromJson)
  final List<ProductSeason> seasons;
  final String? material;
  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  final ProductFit? fit;
  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  final ProductThickness? thickness;
  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  final ProductElasticity? elasticity;
}

List<ClothingStyle> _stylesFromJson(final List<dynamic> json) =>
    ClothingStyle.listFromStrings(json.whereType<String>())!;

List<ProductSeason> _seasonsFromJson(final List<dynamic> json) =>
    ProductSeason.listFromStrings(json.whereType<String>())!;
