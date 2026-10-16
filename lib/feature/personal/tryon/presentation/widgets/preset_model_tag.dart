import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/widgets/glass_pill.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/avatar.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';

class PresetModelTag extends ConsumerWidget {
  const PresetModelTag({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final isPreset = ref.watch(
      userProfileProvider.select(
        (final async) => async.value?.avatar is AvatarFromPreset,
      ),
    );
    final isReplacing = ref.watch(avatarUploadProvider) != null;
    if (!isPreset || isReplacing) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return GlassPill(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.smMd,
        vertical: AppSpacing.xs + AppSpacing.xxs,
      ),
      child: Text(
        '預設模特',
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }
}
