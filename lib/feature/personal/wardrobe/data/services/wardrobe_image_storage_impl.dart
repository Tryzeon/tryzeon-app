import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:tryzeon/core/data/errors/map_exception_to_failure.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/datasources/wardrobe_local_datasource.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/datasources/wardrobe_remote_datasource.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/services/wardrobe_image_storage.dart';
import 'package:typed_result/typed_result.dart';

class WardrobeImageStorageImpl implements WardrobeImageStorage {
  WardrobeImageStorageImpl(this._remoteDataSource, this._localDataSource);

  final WardrobeRemoteDataSource _remoteDataSource;
  final WardrobeLocalDataSource _localDataSource;

  @override
  Future<Result<String, Failure>> upload({
    required final String itemId,
    required final File image,
  }) async {
    final String path;
    final Uint8List bytes;
    try {
      bytes = await image.readAsBytes();
      final extension = p.extension(image.path).toLowerCase();
      path = await _remoteDataSource.uploadImage(
        fileName: '$itemId$extension',
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
