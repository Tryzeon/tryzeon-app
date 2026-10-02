import 'dart:io';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:tryzeon/feature/personal/profile/domain/services/avatar_storage.dart';
import 'package:typed_result/typed_result.dart';

class UpdateUserAvatar {
  UpdateUserAvatar({
    required final UserProfileRepository repository,
    required final AvatarStorage avatarStorage,
  }) : _repository = repository,
       _avatarStorage = avatarStorage;

  final UserProfileRepository _repository;
  final AvatarStorage _avatarStorage;

  Future<Result<void, Failure>> call(final File avatarFile) async {
    final profile = await _repository.getUserProfile();
    if (profile.isFailure) return Err(profile.getError()!);
    final previousPath = profile.get()!.avatarPath;

    final uploaded = await _avatarStorage.upload(avatarFile);
    if (uploaded.isFailure) return Err(uploaded.getError()!);
    final newPath = uploaded.get()!;

    final saved = await _repository.updateAvatarPath(newPath);
    if (saved.isFailure) {
      await _delete(newPath);
      return saved;
    }

    if (previousPath != null && previousPath.isNotEmpty && previousPath != newPath) {
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
