import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class TryOnActionButton extends StatelessWidget {
  const TryOnActionButton({super.key, required this.onTap, this.isDisabled = false});

  final VoidCallback? onTap;
  final bool isDisabled;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Opacity(
        opacity: isDisabled ? AppOpacity.strong : 1.0,
        child: ClipRRect(
          borderRadius: AppRadius.pillAll,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: AppOpacity.overlay),
                border: Border.all(
                  color: colorScheme.onPrimary.withValues(alpha: AppOpacity.medium),
                  width: 1,
                ),
                borderRadius: AppRadius.pillAll,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 20, color: colorScheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '虛擬試穿',
                    style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary),
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
