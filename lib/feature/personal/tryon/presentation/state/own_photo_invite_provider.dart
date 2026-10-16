import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/avatar.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/settings/providers/settings_providers.dart';
import 'package:typed_result/typed_result.dart';

part 'own_photo_invite_provider.g.dart';

/// Once the user has had their own photo, the invite is retired for good, even
/// if they switch back to a preset. An unreadable flag reads as dismissed: a
/// broken store must not keep showing an invite the user may already have
/// closed.
@riverpod
class OwnPhotoInviteDismissedNotifier
    extends _$OwnPhotoInviteDismissedNotifier {
  @override
  Future<bool> build() async {
    final hasOwnPhoto = ref.watch(
      userProfileProvider.select(
        (final async) => async.value?.avatar is AvatarFromUpload,
      ),
    );
    if (hasOwnPhoto) {
      await _persistDismissal();
      return true;
    }

    final result = await ref.read(isOwnPhotoInviteDismissedUseCaseProvider)();
    return result.isSuccess ? result.get()! : true;
  }

  Future<void> dismiss() async {
    state = const AsyncData(true);
    await _persistDismissal();
  }

  Future<void> _persistDismissal() async {
    final result = await ref.read(dismissOwnPhotoInviteUseCaseProvider)();
    if (result.isFailure) {
      AppLogger.error(
        'Failed to persist own-photo invite dismissal',
        result.getError(),
      );
    }
  }
}
