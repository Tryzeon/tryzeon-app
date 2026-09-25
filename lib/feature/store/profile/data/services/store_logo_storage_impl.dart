import 'dart:io';

import 'package:tryzeon/core/data/services/store_images_api.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/store/profile/domain/services/store_logo_storage.dart';
import 'package:typed_result/typed_result.dart';

class StoreLogoStorageImpl implements StoreLogoStorage {
  StoreLogoStorageImpl(this._storeImagesApi);

  final StoreImagesApi _storeImagesApi;

  @override
  Future<Result<String, Failure>> upload({
    required final String storeId,
    required final File logo,
  }) async {
    try {
      return Ok(await _storeImagesApi.uploadStoreLogo(storeId: storeId, logo: logo));
    } catch (e, stackTrace) {
      AppLogger.error('Failed to upload store logo', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> delete({
    required final String storeId,
    required final String path,
  }) async {
    try {
      await _storeImagesApi.deleteImages(storeId: storeId, keys: [path]);
      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete store logo', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
