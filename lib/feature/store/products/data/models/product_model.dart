import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/core/shared/measurements/data/models/measurements_model.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_attributes.dart';

part 'product_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ProductSizeModel {
  const ProductSizeModel({
    required this.id,
    required this.productId,
    required this.name,
    this.measurements,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductSizeModel.fromJson(final Map<String, dynamic> json) =>
      _$ProductSizeModelFromJson(json);

  final String id;
  final String productId;
  final String name;
  final MeasurementsModel? measurements;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => _$ProductSizeModelToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ProductModel {
  const ProductModel({
    required this.storeId,
    required this.name,
    required this.categories,
    required this.price,
    required this.imagePath,
    required this.imageUrl,
    required this.id,
    this.createdAt,
    this.updatedAt,
    this.purchaseLink,
    this.material,
    this.elasticity,
    this.fit,
    this.sizes,
  });

  factory ProductModel.fromJson(final Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  final String storeId;
  final String name;
  final Set<String> categories;
  final double price;
  final String imagePath;
  @JsonKey(includeToJson: false)
  final String imageUrl;
  final String id;
  final String? purchaseLink;
  final String? material;
  final ProductElasticity? elasticity;
  final ProductFit? fit;
  @JsonKey(name: 'product_variants', includeToJson: false)
  final List<ProductSizeModel>? sizes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => _$ProductModelToJson(this);
}
