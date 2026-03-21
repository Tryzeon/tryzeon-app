import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/shared/measurements/entities/measurements.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_attributes.dart';

part 'product.freezed.dart';

@freezed
sealed class CreateProductSizeParams with _$CreateProductSizeParams {
  const factory CreateProductSizeParams({
    required final String name,
    final Measurements? measurements,
  }) = _CreateProductSizeParams;
}

@freezed
sealed class CreateProductParams with _$CreateProductParams {
  const factory CreateProductParams({
    required final String storeId,
    required final String name,
    required final List<String> categoryIds,
    required final double price,
    required final File image,
    final String? purchaseLink,
    final String? material,
    final ProductElasticity? elasticity,
    final ProductFit? fit,
    final List<ClothingStyle>? styles,
    final List<CreateProductSizeParams>? sizes,
  }) = _CreateProductParams;
}

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
    required final List<String> categoryIds,
    required final double price,
    required final String imagePath,
    required final String imageUrl,
    required final String id,
    final String? purchaseLink,
    final String? material,
    final ProductElasticity? elasticity,
    final ProductFit? fit,
    final List<ClothingStyle>? styles,
    final List<ProductSize>? sizes,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) = _Product;
}
