import 'dart:typed_data';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/tryon/data/datasources/tryon_media_datasource.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/tryon/domain/repositories/tryon_media_repository.dart';
import 'package:typed_result/typed_result.dart';

class TryonMediaRepositoryImpl implements TryonMediaRepository {
  TryonMediaRepositoryImpl({required final TryonMediaDataSource dataSource})
    : _dataSource = dataSource;

  final TryonMediaDataSource _dataSource;

  @override
  Future<Result<Uint8List, Failure>> loadImageBytes(final String url) async {
    try {
      return Ok(await _dataSource.downloadImageBytes(url));
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load try-on image bytes', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<Uint8List, Failure>> loadLocalImageBytes(
    final String path,
  ) async {
    try {
      return Ok(await _dataSource.readLocalFile(path));
    } catch (e, stackTrace) {
      AppLogger.error('Failed to read picked garment image', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> share(final TryonResult result) async {
    final url = result.mode == TryonMode.video
        ? result.videoUrl
        : result.imageUrl;
    if (url == null || url.isEmpty) {
      return Err(ValidationFailure('${result.mode.name} URL is missing'));
    }

    String? tempPath;
    try {
      tempPath = await _dataSource.downloadToTempFile(url, result.mode);
      await _dataSource.shareFile(tempPath, result.mode);
      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to share try-on ${result.mode.name}',
        e,
        stackTrace,
      );
      return Err(mapExceptionToFailure(e));
    } finally {
      if (tempPath != null) {
        await _dataSource.deleteTempFile(tempPath);
      }
    }
  }
}
