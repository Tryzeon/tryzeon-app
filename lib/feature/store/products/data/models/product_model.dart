import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/core/shared/measurements/data/models/measurements_model.dart';

part 'product_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ProductSizeModel {
  const ProductSizeModel({
    required this.id,
    required this.productId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.measurements,
  });

  factory ProductSizeModel.fromJson(final Map<String, dynamic> json) =>
      _$ProductSizeModelFromJson(json);

  final String id;
  final String productId;
  final String name;
  final MeasurementsModel? measurements;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => _$ProductSizeModelToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ProductModel {
  const ProductModel({
    required this.storeId,
    required this.name,
    required this.categoryIds,
    required this.price,
    required this.imagePaths,
    required this.imageUrls,
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.purchaseLink,
    this.material,
    this.elasticity,
    this.fit,
    this.thickness,
    this.styles,
    this.sizes,
  });

  factory ProductModel.fromJson(final Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  final String storeId;
  final String name;
  final List<String> categoryIds;
  final double price;
  final List<String> imagePaths;
  @JsonKey(includeToJson: false)
  final List<String> imageUrls;
  final String id;
  final String? purchaseLink;
  final String? material;
  final String? elasticity;
  final String? fit;
  final String? thickness;
  final List<String>? styles;
  @JsonKey(name: 'product_variants', includeToJson: false)
  final List<ProductSizeModel>? sizes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => _$ProductModelToJson(this);
}
