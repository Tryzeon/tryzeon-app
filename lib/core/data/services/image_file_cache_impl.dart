import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart' as fcm;
import 'package:tryzeon/core/data/services/image_file_cache.dart';
import 'package:tryzeon/core/utils/app_logger.dart';

class ImageFileCacheImpl implements ImageFileCache {
  ImageFileCacheImpl(this._cacheManager);

  final fcm.BaseCacheManager _cacheManager;

  @override
  Future<File> saveImage(final Uint8List bytes, final String filePath) async {
    try {
      return await _cacheManager.putFile(filePath, bytes, key: filePath);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save image to $filePath', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<File?> getImage(
    final String filePath, {
    final String? downloadUrl,
  }) async {
    try {
      if (downloadUrl != null && downloadUrl.isNotEmpty) {
        return await _cacheManager.getSingleFile(downloadUrl, key: filePath);
      }

      final fileInfo = await _cacheManager.getFileFromCache(filePath);
      return fileInfo?.file;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get image from $filePath', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteImage(final String filePath) async {
    try {
      await _cacheManager.removeFile(filePath);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete image at $filePath', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _cacheManager.emptyCache();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to empty cache', e, stackTrace);
    }
  }
}
