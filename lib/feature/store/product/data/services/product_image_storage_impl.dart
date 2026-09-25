import 'dart:io';

import 'package:tryzeon/core/data/services/store_images_api.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/store/product/data/datasources/product_local_datasource.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_image_storage.dart';
import 'package:typed_result/typed_result.dart';

class ProductImageStorageImpl implements ProductImageStorage {
  ProductImageStorageImpl(this._storeImagesApi, this._localDataSource);

  final StoreImagesApi _storeImagesApi;
  final ProductLocalDataSource _localDataSource;

  @override
  Future<Result<List<String>, Failure>> upload({
    required final String storeId,
    required final String productId,
    required final List<File> images,
  }) async {
    final List<String> paths;
    try {
      paths = await _storeImagesApi.uploadProductImages(
        storeId: storeId,
        productId: productId,
        images: images,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to upload product images', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }

    for (var i = 0; i < images.length; i++) {
      try {
        await _localDataSource.saveProductImage(await images[i].readAsBytes(), paths[i]);
      } catch (e, stackTrace) {
        AppLogger.warning('Failed to cache uploaded product image', e, stackTrace);
      }
    }
    return Ok(paths);
  }

  @override
  Future<Result<void, Failure>> delete({
    required final String storeId,
    required final List<String> paths,
  }) async {
    try {
      await _storeImagesApi.deleteImages(storeId: storeId, keys: paths);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete product images', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }

    try {
      await _localDataSource.deleteProductImages(paths);
    } catch (e, stackTrace) {
      AppLogger.warning('Failed to evict cached product images', e, stackTrace);
    }
    return const Ok(null);
  }
}
