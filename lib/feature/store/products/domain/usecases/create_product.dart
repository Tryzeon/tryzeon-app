import 'dart:io';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/repositories/product_repository.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_attributes.dart';
import 'package:typed_result/typed_result.dart';

class CreateProduct {
  CreateProduct(this._repository);
  final ProductRepository _repository;

  Future<Result<void, Failure>> call({
    required final String storeId,
    required final String name,
    required final Set<String> categories,
    required final double price,
    required final File image,
    final String? purchaseLink,
    final String? material,
    final ProductElasticity? elasticity,
    final ProductFit? fit,
    final List<ProductSize>? sizes,
  }) => _repository.createProduct(
    storeId: storeId,
    name: name,
    categories: categories,
    price: price,
    image: image,
    purchaseLink: purchaseLink,
    material: material,
    elasticity: elasticity,
    fit: fit,
    sizes: sizes,
  );
}
