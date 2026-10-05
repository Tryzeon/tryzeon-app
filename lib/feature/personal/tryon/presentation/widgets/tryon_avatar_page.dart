import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/widgets/pinch_to_zoom.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/model_choice_picker.dart';

class TryonAvatarPage extends HookConsumerWidget {
  const TryonAvatarPage({
    super.key,
    required this.onUploadOwnPhoto,
    required this.onPresetSelected,
  });

  final VoidCallback onUploadOwnPhoto;
  final ValueChanged<PresetAvatar> onPresetSelected;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    useAutomaticKeepAlive();

    final uploadingFile = ref.watch(avatarUploadProvider);
    final avatarAsync = ref.watch(avatarFileProvider);

    final file = uploadingFile ?? avatarAsync.value;
    if (file != null) {
      return GestureDetector(
        onTap: onUploadOwnPhoto,
        child: _AvatarImageItem(
          imageProvider: FileImage(file),
          isBusy: uploadingFile != null || avatarAsync.isLoading,
        ),
      );
    }
    if (avatarAsync.isLoading) return const _AvatarLoadingItem();

    final gender = ref.watch(userProfileProvider).value?.gender;
    return _AvatarEmptyState(
      presets: PresetAvatar.forGender(gender),
      onPresetSelected: onPresetSelected,
      onUploadOwnPhoto: onUploadOwnPhoto,
    );
  }
}

class _AvatarImageItem extends StatelessWidget {
  const _AvatarImageItem({required this.imageProvider, required this.isBusy});

  final ImageProvider imageProvider;
  final bool isBusy;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        PinchToZoom(
          child: Image(image: imageProvider, fit: BoxFit.cover, gaplessPlayback: true),
        ),
        if (isBusy)
          ColoredBox(
            color: colorScheme.scrim.withValues(alpha: AppOpacity.overlay),
            child: Center(
              child: SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  strokeWidth: AppStroke.medium,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AvatarLoadingItem extends StatelessWidget {
  const _AvatarLoadingItem();

  @override
  Widget build(final BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _AvatarEmptyState extends StatelessWidget {
  const _AvatarEmptyState({
    required this.presets,
    required this.onPresetSelected,
    required this.onUploadOwnPhoto,
  });

  final List<PresetAvatar> presets;
  final ValueChanged<PresetAvatar> onPresetSelected;
  final VoidCallback onUploadOwnPhoto;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ColoredBox(
      color: colorScheme.surface,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('選擇你的試穿模特', style: theme.textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '先用預設模特試穿，或上傳自己的全身照',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ModelChoicePicker(
                presets: presets,
                onPresetSelected: onPresetSelected,
                onUploadOwnPhoto: onUploadOwnPhoto,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
