import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/core/shared/measurements/data/models/size_measurements_model.dart';
import 'package:tryzeon/core/shared/measurements/entities/size_measurements.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';

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

  factory ProductSizeModel.fromEntity(final ProductSize entity) {
    return ProductSizeModel(
      id: entity.id,
      productId: entity.productId,
      name: entity.name,
      measurements: entity.measurements != null
          ? SizeMeasurementsModel.fromEntity(entity.measurements!)
          : null,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory ProductSizeModel.fromJson(final Map<String, dynamic> json) =>
      _$ProductSizeModelFromJson(json);

  final String id;
  final String productId;
  final String name;
  final SizeMeasurementsModel? measurements;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => _$ProductSizeModelToJson(this);

  ProductSize toEntity() {
    return ProductSize(
      id: id,
      productId: productId,
      name: name,
      measurements: measurements?.toEntity() ?? const SizeMeasurements(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
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
    this.purchaseLink,
    this.sizes,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductModel.fromEntity(final Product entity) {
    return ProductModel(
      id: entity.id,
      storeId: entity.storeId,
      name: entity.name,
      categories: entity.categories,
      price: entity.price,
      imagePath: entity.imagePath,
      imageUrl: entity.imageUrl,
      purchaseLink: entity.purchaseLink,
      sizes: entity.sizes?.map(ProductSizeModel.fromEntity).toList(),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

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
  @JsonKey(name: 'product_variants', includeToJson: false)
  final List<ProductSizeModel>? sizes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => _$ProductModelToJson(this);

  Product toEntity() {
    return Product(
      storeId: storeId,
      name: name,
      categories: categories,
      price: price,
      imagePath: imagePath,
      imageUrl: imageUrl,
      id: id,
      purchaseLink: purchaseLink,
      sizes: sizes?.map((final s) => s.toEntity()).toList(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
