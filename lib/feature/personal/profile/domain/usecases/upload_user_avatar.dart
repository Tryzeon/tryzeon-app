import 'dart:io';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:tryzeon/feature/personal/profile/domain/services/avatar_storage.dart';
import 'package:typed_result/typed_result.dart';

class UploadUserAvatar {
  UploadUserAvatar({
    required final UserProfileRepository repository,
    required final AvatarStorage avatarStorage,
  }) : _repository = repository,
       _avatarStorage = avatarStorage;

  final UserProfileRepository _repository;
  final AvatarStorage _avatarStorage;

  Future<Result<void, Failure>> call(final File avatarFile) async {
    final profile = await _repository.getUserProfile(forceRefresh: true);
    if (profile.isFailure) return Err(profile.getError()!);
    final previous = profile.get()!.avatar;

    final uploaded = await _avatarStorage.upload(avatarFile);
    if (uploaded.isFailure) return Err(uploaded.getError()!);
    final path = uploaded.get()!;

    final saved = await _repository.updateAvatar(Avatar.uploaded(path));
    if (saved.isFailure) {
      await _delete(path);
      return saved;
    }

    if (previous case AvatarFromUpload(
      path: final previousPath,
    ) when previousPath != path) {
      await _delete(previousPath);
    }
    return const Ok(null);
  }

  Future<void> _delete(final String path) async {
    final deleted = await _avatarStorage.delete(path);
    if (deleted.isFailure) {
      AppLogger.warning('Failed to delete avatar $path', deleted.getError());
    }
  }
}
