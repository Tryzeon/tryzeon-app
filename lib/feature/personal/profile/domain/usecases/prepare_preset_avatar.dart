import 'dart:io';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/services/preset_avatar_source.dart';
import 'package:typed_result/typed_result.dart';

class PreparePresetAvatar {
  PreparePresetAvatar(this._presetAvatarSource);

  final PresetAvatarSource _presetAvatarSource;

  Future<Result<File, Failure>> call(final PresetAvatar preset) =>
      _presetAvatarSource.fileFor(preset);
}
