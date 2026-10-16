import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:tryzeon/feature/personal/profile/domain/services/avatar_storage.dart';
import 'package:typed_result/typed_result.dart';

class SelectPresetAvatar {
  SelectPresetAvatar({
    required final UserProfileRepository repository,
    required final AvatarStorage avatarStorage,
  }) : _repository = repository,
       _avatarStorage = avatarStorage;

  final UserProfileRepository _repository;
  final AvatarStorage _avatarStorage;

  Future<Result<void, Failure>> call(final PresetAvatar preset) async {
    final profile = await _repository.getUserProfile(forceRefresh: true);
    if (profile.isFailure) return Err(profile.getError()!);
    final previous = profile.get()!.avatar;

    final saved = await _repository.updateAvatar(Avatar.preset(preset));
    if (saved.isFailure) return saved;

    if (previous case AvatarFromUpload(:final path)) {
      final deleted = await _avatarStorage.delete(path);
      if (deleted.isFailure) {
        AppLogger.warning('Failed to delete avatar $path', deleted.getError());
      }
    }
    return const Ok(null);
  }
}
