import 'dart:io';

import 'package:tryzeon/core/data/services/store_images_api.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_image_storage.dart';
import 'package:typed_result/typed_result.dart';

class ProductImageStorageImpl implements ProductImageStorage {
  ProductImageStorageImpl(this._storeImagesApi);

  final StoreImagesApi _storeImagesApi;

  @override
  Future<Result<List<String>, Failure>> upload({
    required final String storeId,
    required final String productId,
    required final List<File> images,
  }) async {
    try {
      final paths = await _storeImagesApi.uploadProductImages(
        storeId: storeId,
        productId: productId,
        images: images,
      );
      return Ok(paths);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to upload product images', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> delete({
    required final String storeId,
    required final List<String> paths,
  }) async {
    try {
      await _storeImagesApi.deleteImages(storeId: storeId, keys: paths);
      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete product images', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
