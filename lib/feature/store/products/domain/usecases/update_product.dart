import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/repositories/product_repository.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/image_item.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_attributes.dart';
import 'package:typed_result/typed_result.dart';

class UpdateProduct {
  UpdateProduct(this._repository);
  final ProductRepository _repository;

  Future<Result<void, Failure>> call({
    required final String productId,
    required final List<ImageItem> finalImageOrder,
    required final List<CreateProductSizeParams> sizesToAdd,
    required final List<ProductSize> sizesToUpdate,
    required final List<String> sizeIdsToDelete,
    required final String name,
    required final List<String> categoryIds,
    required final double price,
    final String? purchaseLink,
    final String? material,
    final ProductElasticity? elasticity,
    final ProductFit? fit,
    final List<ClothingStyle>? styles,
  }) async {
    final originalResult = await _repository.getProductById(productId);

    if (originalResult.isFailure) {
      return Err(originalResult.getError()!);
    }
    final original = originalResult.get()!;

    return _repository.updateProduct(
      original: original,
      finalImageOrder: finalImageOrder,
      sizesToAdd: sizesToAdd,
      sizesToUpdate: sizesToUpdate,
      sizeIdsToDelete: sizeIdsToDelete,
      name: name,
      categoryIds: categoryIds,
      price: price,
      purchaseLink: purchaseLink,
      material: material,
      elasticity: elasticity,
      fit: fit,
      styles: styles,
    );
  }
}
