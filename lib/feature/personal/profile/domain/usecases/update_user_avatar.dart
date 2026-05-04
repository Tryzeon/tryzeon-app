import 'dart:io';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:typed_result/typed_result.dart';

class UpdateUserAvatar {
  UpdateUserAvatar(this._repository);

  final UserProfileRepository _repository;

  Future<Result<void, Failure>> call({
    required final File avatarFile,
    final String? previousAvatarPath,
  }) {
    return _repository.updateUserAvatar(
      avatarFile: avatarFile,
      previousAvatarPath: previousAvatarPath,
    );
  }
}
