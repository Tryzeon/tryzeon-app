import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/core/shared/measurements/entities/size_measurements.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';

part 'product_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ProductSizeModel {
  const ProductSizeModel({
    this.id,
    this.productId,
    required this.name,
    this.height,
    this.chest,
    this.waist,
    this.hips,
    this.shoulder,
    this.sleeve,
    this.heightOffset,
    this.chestOffset,
    this.waistOffset,
    this.hipsOffset,
    this.shoulderOffset,
    this.sleeveOffset,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductSizeModel.fromEntity(final ProductSize entity) {
    return ProductSizeModel(
      id: entity.id,
      productId: entity.productId,
      name: entity.name,
      height: entity.measurements.height,
      chest: entity.measurements.chest,
      waist: entity.measurements.waist,
      hips: entity.measurements.hips,
      shoulder: entity.measurements.shoulder,
      sleeve: entity.measurements.sleeve,
      heightOffset: entity.measurements.heightOffset,
      chestOffset: entity.measurements.chestOffset,
      waistOffset: entity.measurements.waistOffset,
      hipsOffset: entity.measurements.hipsOffset,
      shoulderOffset: entity.measurements.shoulderOffset,
      sleeveOffset: entity.measurements.sleeveOffset,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory ProductSizeModel.fromJson(final Map<String, dynamic> json) =>
      _$ProductSizeModelFromJson(json);

  final String? id;
  final String? productId;
  final String name;
  final double? height;
  final double? chest;
  final double? waist;
  final double? hips;
  final double? shoulder;
  final double? sleeve;
  final double? heightOffset;
  final double? chestOffset;
  final double? waistOffset;
  final double? hipsOffset;
  final double? shoulderOffset;
  final double? sleeveOffset;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => _$ProductSizeModelToJson(this);

  ProductSize toEntity() {
    return ProductSize(
      id: id,
      productId: productId,
      name: name,
      measurements: SizeMeasurements(
        height: height,
        chest: chest,
        waist: waist,
        hips: hips,
        shoulder: shoulder,
        sleeve: sleeve,
        heightOffset: heightOffset,
        chestOffset: chestOffset,
        waistOffset: waistOffset,
        hipsOffset: hipsOffset,
        shoulderOffset: shoulderOffset,
        sleeveOffset: sleeveOffset,
      ),
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
    required this.types,
    required this.price,
    required this.imagePath,
    required this.imageUrl,
    this.id,
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
      types: entity.types,
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
  final Set<String> types;
  final double price;
  final String imagePath;
  @JsonKey(includeToJson: false)
  final String imageUrl;
  final String? id;
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
      types: types,
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
