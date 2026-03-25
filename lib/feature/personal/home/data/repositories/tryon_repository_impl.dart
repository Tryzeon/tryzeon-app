import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/home/data/datasources/tryon_remote_data_source.dart';
import 'package:tryzeon/feature/personal/home/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/home/domain/entities/tryon_params.dart';
import 'package:tryzeon/feature/personal/home/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/home/domain/repositories/tryon_repository.dart';
import 'package:typed_result/typed_result.dart';

class TryOnRepositoryImpl implements TryOnRepository {
  TryOnRepositoryImpl({required final TryonRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final TryonRemoteDataSource _remoteDataSource;

  @override
  Future<Result<TryonResult, Failure>> tryon(final TryOnParams params) async {
    try {
      final data = await _remoteDataSource.tryon(params);

      String? videoPath;

      // If video mode, save base64 video to local file
      if (params.mode == TryOnMode.video && data['video'] != null) {
        final videoBase64 = data['video'] as String;
        final videoBytes = base64Decode(videoBase64);

        // Save to temporary directory
        final tempDir = await getTemporaryDirectory();
        final videoFile = File(
          '${tempDir.path}/tryon_${DateTime.now().millisecondsSinceEpoch}.mp4',
        );
        await videoFile.writeAsBytes(videoBytes);

        videoPath = videoFile.path;
      }

      return Ok(
        TryonResult(
          imageBase64: data['image'] as String?,
          videoPath: videoPath,
          mode: params.mode,
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Virtual try-on failed', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
