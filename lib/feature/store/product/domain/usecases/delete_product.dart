import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/domain/repositories/product_repository.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_image_storage.dart';
import 'package:typed_result/typed_result.dart';

class DeleteProduct {
  DeleteProduct({
    required final ProductRepository repository,
    required final ProductImageStorage imageStorage,
  }) : _repository = repository,
       _imageStorage = imageStorage;

  final ProductRepository _repository;
  final ProductImageStorage _imageStorage;

  Future<Result<void, Failure>> call(final Product product) async {
    final deleted = await _repository.deleteProduct(
      storeId: product.storeId,
      productId: product.id,
    );
    if (deleted.isFailure) return deleted;

    if (product.imagePaths.isNotEmpty) {
      final imagesDeleted = await _imageStorage.delete(
        storeId: product.storeId,
        paths: product.imagePaths,
      );
      if (imagesDeleted.isFailure) {
        AppLogger.warning(
          'Failed to delete images of product ${product.id}',
          imagesDeleted.getError(),
        );
      }
    }
    return const Ok(null);
  }
}
