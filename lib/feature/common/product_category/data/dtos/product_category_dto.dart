import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';

part 'product_category_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ProductCategoryDto {
  const ProductCategoryDto({
    required this.id,
    required this.code,
    required this.name,
    required this.defaultGarmentType,
    this.gender,
    this.imageMale,
    this.imageFemale,
    this.imageMaleUrl,
    this.imageFemaleUrl,
  });

  factory ProductCategoryDto.fromJson(final Map<String, dynamic> json) =>
      _$ProductCategoryDtoFromJson(json);

  final String id;
  final String code;
  final String name;
  @JsonKey(unknownEnumValue: GarmentType.others)
  final GarmentType defaultGarmentType;

  /// Applicability. `unisex` = both.
  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  final ProductGender? gender;

  /// Per-gender model imagery (R2 paths).
  final String? imageMale;
  final String? imageFemale;

  @JsonKey(includeToJson: false)
  final String? imageMaleUrl;
  @JsonKey(includeToJson: false)
  final String? imageFemaleUrl;

  Map<String, dynamic> toJson() => _$ProductCategoryDtoToJson(this);
}
