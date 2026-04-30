import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class TryOnIndicator extends StatelessWidget {
  const TryOnIndicator({
    super.key,
    required this.currentTryonIndex,
    required this.tryonImagesCount,
  });

  final int currentTryonIndex;
  final int tryonImagesCount;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.mdLg),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: AppOpacity.strong),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: colorScheme.onSurface.withValues(alpha: AppOpacity.medium),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (currentTryonIndex == -1)
              Text(
                '原圖',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface,
                  shadows: [
                    Shadow(
                      blurRadius: 4.0,
                      color: colorScheme.surface.withValues(alpha: AppOpacity.overlay),
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(tryonImagesCount, (final index) {
                  final isSelected = currentTryonIndex == index;
                  return AnimatedContainer(
                    duration: AppDuration.slow,
                    curve: AppCurves.standard,
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    width: isSelected ? AppSpacing.smMd : AppSpacing.sm,
                    height: AppSpacing.sm,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withValues(alpha: AppOpacity.overlay),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}
