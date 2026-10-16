import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/widgets/glass_surface.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/avatar.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/own_photo_invite_provider.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_gallery_entry.dart';
import 'package:tryzeon/feature/personal/tutorial/presentation/controllers/tutorial_controller.dart';
import 'package:tryzeon/feature/personal/tutorial/presentation/state/tutorial_state.dart';

/// Only a finished photo try-on qualifies: retrying a video would spend the
/// video quota. Gated on the tutorial's live state rather than the profile's
/// `isTutorialCompleted`, which flips while the tutorial's review step is still
/// on screen.
class OwnPhotoInviteCard extends ConsumerWidget {
  const OwnPhotoInviteCard({
    super.key,
    required this.entry,
    required this.onUpload,
  });

  final TryonGalleryEntry entry;
  final VoidCallback onUpload;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final isPreset = ref.watch(
      userProfileProvider.select(
        (final async) => async.value?.avatar is AvatarFromPreset,
      ),
    );
    final isTutorialInactive = ref.watch(
      tutorialControllerProvider.select(
        (final state) => state is TutorialInactive,
      ),
    );
    final isReplacing = ref.watch(avatarUploadProvider) != null;
    final isDismissed =
        ref.watch(ownPhotoInviteDismissedProvider).value ?? true;
    final isPhotoTryon =
        entry is FinishedTryonEntry && entry.mode == TryonMode.image;

    if (!isPreset ||
        !isTutorialInactive ||
        isReplacing ||
        isDismissed ||
        !isPhotoTryon) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final onPhoto = theme.colorScheme.onPrimary;
    final onPhotoMuted = onPhoto.withValues(alpha: AppOpacity.overlay);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassSurface(
        borderRadius: AppRadius.dialogAll,
        padding: const EdgeInsets.only(
          left: AppSpacing.md,
          top: AppSpacing.md,
          bottom: AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '穿在你身上會是什麼樣子？',
                    style: theme.textTheme.titleSmall?.copyWith(color: onPhoto),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '上傳一張全身照，用你的身形試穿',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: onPhotoMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.smMd),
                  FilledButton.icon(
                    onPressed: onUpload,
                    style: FilledButton.styleFrom(
                      backgroundColor: onPhoto,
                      foregroundColor: theme.colorScheme.onSurface,
                      shape: const StadiumBorder(),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                    ),
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: const Text('上傳全身照'),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: '關閉',
              visualDensity: VisualDensity.compact,
              color: onPhotoMuted,
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () =>
                  ref.read(ownPhotoInviteDismissedProvider.notifier).dismiss(),
            ),
          ],
        ),
      ),
    );
  }
}
