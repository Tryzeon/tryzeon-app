import 'dart:io';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/repositories/product_repository.dart';
import 'package:typed_result/typed_result.dart';

class UpdateProduct {
  UpdateProduct(this._repository);
  final ProductRepository _repository;

  Future<Result<void, Failure>> call({
    required final Product original,
    required final Product target,
    required final List<CreateProductSizeParams> sizesToAdd,
    required final List<ProductSize> sizesToUpdate,
    required final List<String> sizeIdsToDelete,
    final File? newImage,
  }) => _repository.updateProduct(
    original: original,
    target: target,
    sizesToAdd: sizesToAdd,
    sizesToUpdate: sizesToUpdate,
    sizeIdsToDelete: sizeIdsToDelete,
    newImage: newImage,
  );
}
