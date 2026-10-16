import 'dart:io';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:tryzeon/feature/personal/profile/domain/services/preset_avatar_source.dart';
import 'package:typed_result/typed_result.dart';

class GetUserAvatar {
  GetUserAvatar({
    required final UserProfileRepository repository,
    required final PresetAvatarSource presetAvatarSource,
  }) : _repository = repository,
       _presetAvatarSource = presetAvatarSource;

  final UserProfileRepository _repository;
  final PresetAvatarSource _presetAvatarSource;

  Future<Result<File, Failure>> call(final Avatar avatar) => switch (avatar) {
    AvatarFromPreset(:final preset) => _presetAvatarSource.fileFor(preset),
    AvatarFromUpload(:final path) => _repository.getUserAvatar(path),
  };
}
