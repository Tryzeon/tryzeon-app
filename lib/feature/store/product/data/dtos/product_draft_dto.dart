import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';

part 'product_draft_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, createFactory: false)
class ProductDraftDto {
  const ProductDraftDto({
    required this.name,
    required this.categoryId,
    required this.garmentType,
    required this.price,
    required this.gender,
    required this.status,
    this.purchaseLink,
    this.description,
    this.material,
    this.elasticity,
    this.fit,
    this.thickness,
    this.styles,
    this.seasons,
  });

  final String name;
  final String categoryId;
  final GarmentType garmentType;
  final double price;
  final ProductGender gender;
  final ProductStatus status;
  final String? purchaseLink;
  final String? description;
  final String? material;
  final ProductElasticity? elasticity;
  final ProductFit? fit;
  final ProductThickness? thickness;
  final List<ClothingStyle>? styles;
  final List<ProductSeason>? seasons;

  Map<String, dynamic> toJson() => _$ProductDraftDtoToJson(this);
}
