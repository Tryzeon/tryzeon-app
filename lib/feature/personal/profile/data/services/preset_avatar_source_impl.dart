import 'dart:io';

import 'package:tryzeon/core/data/errors/map_exception_to_failure.dart';
import 'package:tryzeon/core/data/services/image_file_cache.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/core/utils/public_image_url.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/services/preset_avatar_source.dart';
import 'package:typed_result/typed_result.dart';

class PresetAvatarSourceImpl implements PresetAvatarSource {
  PresetAvatarSourceImpl(this._imageFileCache);

  final ImageFileCache _imageFileCache;

  static String _keyOf(final PresetAvatar preset) =>
      'presets/${preset.name}.jpg';

  @override
  Future<Result<File, Failure>> fileFor(final PresetAvatar preset) async {
    final key = _keyOf(preset);
    try {
      final file = await _imageFileCache.getImage(
        key,
        downloadUrl: PublicImageUrl.of(key),
      );
      if (file == null) {
        return const Err(UnknownFailure('無法取得預設模特圖片'));
      }
      return Ok(file);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to load preset avatar ${preset.name}',
        e,
        stackTrace,
      );
      return Err(mapExceptionToFailure(e));
    }
  }
}
