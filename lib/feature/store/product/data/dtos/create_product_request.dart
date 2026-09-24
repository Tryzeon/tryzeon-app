import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';

part 'create_product_request.g.dart';

/// The id is generated client-side (UUID v4) and decides the R2 image path.
@JsonSerializable(fieldRename: FieldRename.snake)
class CreateProductRequest {
  const CreateProductRequest({
    required this.id,
    required this.storeId,
    required this.name,
    required this.categoryId,
    required this.garmentType,
    required this.price,
    required this.imagePaths,
    this.gender,
    this.purchaseLink,
    this.description,
    this.material,
    this.elasticity,
    this.fit,
    this.thickness,
    this.styles,
    this.seasons,
  });

  final String id;
  final String storeId;
  final String name;
  final String categoryId;
  final GarmentType garmentType;
  final double price;
  final List<String> imagePaths;
  final ProductGender? gender;
  final String? purchaseLink;
  final String? description;
  final String? material;
  final ProductElasticity? elasticity;
  final ProductFit? fit;
  final ProductThickness? thickness;
  final List<ClothingStyle>? styles;
  final List<ProductSeason>? seasons;

  Map<String, dynamic> toJson() => _$CreateProductRequestToJson(this);
}
