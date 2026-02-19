import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/shared/measurements/entities/measurements.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_attributes.dart';

part 'product.freezed.dart';

@freezed
sealed class ProductSize with _$ProductSize {
  const factory ProductSize({
    required final String id,
    required final String productId,
    required final String name,
    final Measurements? measurements,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) = _ProductSize;
}

@freezed
sealed class Product with _$Product {
  const factory Product({
    required final String storeId,
    required final String name,
    required final Set<String> categories,
    required final double price,
    required final String imagePath,
    required final String imageUrl,
    required final String id,
    final String? purchaseLink,
    final String? material,
    final ProductElasticity? elasticity,
    final ProductFit? fit,
    final List<ProductSize>? sizes,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) = _Product;
}
