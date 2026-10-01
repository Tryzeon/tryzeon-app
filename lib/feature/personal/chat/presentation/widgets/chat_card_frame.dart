import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/tryon/tryon.dart';

class ChatCardFrame extends HookWidget {
  const ChatCardFrame({
    super.key,
    required this.image,
    required this.onTap,
    required this.onTryon,
    required this.details,
    this.tag,
  });

  final Widget image;
  final VoidCallback onTap;
  final VoidCallback onTryon;
  final List<Widget> details;
  final String? tag;

  static const double _pressedScale = 0.97;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pressed = useState(false);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onTapDown: (final _) => pressed.value = true,
      onTapUp: (final _) => pressed.value = false,
      onTapCancel: () => pressed.value = false,
      child: AnimatedScale(
        scale: pressed.value ? _pressedScale : 1,
        duration: AppDuration.quick,
        curve: AppCurves.standard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 3 / 4,
              child: ClipRRect(
                borderRadius: AppRadius.cardAll,
                child: ColoredBox(
                  color: colorScheme.surfaceContainerLow,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      image,
                      if (tag != null)
                        Positioned(
                          top: AppSpacing.sm,
                          left: AppSpacing.sm,
                          child: _Tag(label: tag!),
                        ),
                      Positioned(
                        bottom: AppSpacing.sm,
                        right: AppSpacing.sm,
                        child: TryonFab(onTap: onTryon),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...details,
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: AppRadius.pillAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onPrimaryContainer,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
