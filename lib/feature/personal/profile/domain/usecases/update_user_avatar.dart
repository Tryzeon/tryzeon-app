import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:tryzeon/feature/personal/profile/domain/services/avatar_storage.dart';
import 'package:typed_result/typed_result.dart';

part 'update_user_avatar.freezed.dart';

@freezed
sealed class UpdateUserAvatarParams with _$UpdateUserAvatarParams {
  const factory UpdateUserAvatarParams({
    required final File avatarFile,
    final String? previousAvatarPath,
  }) = _UpdateUserAvatarParams;
}

class UpdateUserAvatar {
  UpdateUserAvatar({
    required final UserProfileRepository repository,
    required final AvatarStorage avatarStorage,
  }) : _repository = repository,
       _avatarStorage = avatarStorage;

  final UserProfileRepository _repository;
  final AvatarStorage _avatarStorage;

  Future<Result<void, Failure>> call(final UpdateUserAvatarParams params) async {
    final uploaded = await _avatarStorage.upload(params.avatarFile);
    if (uploaded.isFailure) return Err(uploaded.getError()!);
    final newPath = uploaded.get()!;

    final saved = await _repository.updateAvatarPath(newPath);
    if (saved.isFailure) {
      await _delete(newPath);
      return saved;
    }

    final previousPath = params.previousAvatarPath;
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
