import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:typed_result/typed_result.dart';

import '../../domain/services/wardrobe_image_storage.dart';
import '../datasources/wardrobe_local_datasource.dart';
import '../datasources/wardrobe_remote_datasource.dart';

class WardrobeImageStorageImpl implements WardrobeImageStorage {
  WardrobeImageStorageImpl(this._remoteDataSource, this._localDataSource);

  final WardrobeRemoteDataSource _remoteDataSource;
  final WardrobeLocalDataSource _localDataSource;

  @override
  Future<Result<String, Failure>> upload({
    required final File image,
    required final GarmentType garmentType,
  }) async {
    final String path;
    final Uint8List bytes;
    try {
      bytes = await image.readAsBytes();
      path = await _remoteDataSource.uploadImage(
        garmentType: garmentType.value,
        fileName: p.basename(image.path),
        bytes: bytes,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to upload wardrobe image', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }

    try {
      await _localDataSource.saveImage(bytes, path);
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Failed to cache uploaded wardrobe image',
        e,
        stackTrace,
      );
    }
    return Ok(path);
  }

  @override
  Future<Result<void, Failure>> delete(final String path) async {
    try {
      await _remoteDataSource.deleteImage(path);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete wardrobe image', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }

    try {
      await _localDataSource.deleteImage(path);
    } catch (e, stackTrace) {
      AppLogger.warning('Failed to evict cached wardrobe image', e, stackTrace);
    }
    return const Ok(null);
  }
}
