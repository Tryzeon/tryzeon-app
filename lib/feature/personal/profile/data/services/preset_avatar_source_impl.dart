import 'dart:io';

import 'package:flutter/services.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/services/preset_avatar_source.dart';
import 'package:typed_result/typed_result.dart';

class PresetAvatarSourceImpl implements PresetAvatarSource {
  PresetAvatarSourceImpl({
    required final AssetBundle bundle,
    required final Future<Directory> Function() temporaryDirectory,
  }) : _bundle = bundle,
       _temporaryDirectory = temporaryDirectory;

  final AssetBundle _bundle;
  final Future<Directory> Function() _temporaryDirectory;

  @override
  Future<Result<File, Failure>> fileFor(final PresetAvatar preset) async {
    try {
      final data = await _bundle.load(preset.assetPath);
      final directory = await _temporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File(
        '${directory.path}/preset_${preset.name}_$timestamp.jpg',
      );
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      return Ok(file);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to prepare preset avatar ${preset.name}',
        e,
        stackTrace,
      );
      return Err(mapExceptionToFailure(e));
    }
  }
}
