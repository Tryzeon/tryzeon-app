import 'dart:io';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';
import 'package:typed_result/typed_result.dart';

abstract class PresetAvatarSource {
  Future<Result<File, Failure>> fileFor(final PresetAvatar preset);
}
