import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/widgets/glass_pill.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/avatar.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';

class PresetModelTag extends HookConsumerWidget {
  const PresetModelTag({super.key, required this.onTap});

  static const double _iconSize = 18;
  static const double _pressedScale = 0.95;

  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final pressed = useState(false);
    final isPreset = ref.watch(
      userProfileProvider.select(
        (final async) => async.value?.avatar is AvatarFromPreset,
      ),
    );
    final isReplacing = ref.watch(avatarUploadProvider) != null;
    if (!isPreset || isReplacing) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      onTapDown: (final _) => pressed.value = true,
      onTapUp: (final _) => pressed.value = false,
      onTapCancel: () => pressed.value = false,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: kMinInteractiveDimension,
          minHeight: kMinInteractiveDimension,
        ),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: AnimatedScale(
            scale: pressed.value ? _pressedScale : 1,
            duration: AppDuration.quick,
            curve: AppCurves.standard,
            child: GlassPill(
              padding: const EdgeInsets.only(
                left: AppSpacing.smMd,
                right: AppSpacing.sm,
                top: AppSpacing.sm,
                bottom: AppSpacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '預設模特',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: onPrimary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Icon(
                    Icons.expand_more_rounded,
                    size: _iconSize,
                    color: onPrimary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
