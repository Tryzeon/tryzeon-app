import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';

/// Two styles per row, lazily built; callers normally wrap it in an `Expanded`.
class StylePreferenceGrid extends StatelessWidget {
  const StylePreferenceGrid({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  static const _columns = 2;
  static const _imageAspectRatio = 3 / 4;

  final Set<ClothingStyle> selected;
  final void Function(ClothingStyle style) onToggle;

  @override
  Widget build(final BuildContext context) {
    final styles = ClothingStyle.values;
    final rowCount = (styles.length + _columns - 1) ~/ _columns;

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      itemCount: rowCount,
      separatorBuilder: (final _, final _) =>
          const SizedBox(height: AppSpacing.mdLg),
      itemBuilder: (final context, final row) {
        final first = row * _columns;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var column = 0; column < _columns; column++) ...[
              if (column > 0) const SizedBox(width: AppSpacing.md),
              Expanded(
                child: first + column < styles.length
                    ? _StyleCard(
                        style: styles[first + column],
                        isSelected: selected.contains(styles[first + column]),
                        onTap: onToggle,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _StyleCard extends StatelessWidget {
  const _StyleCard({
    required this.style,
    required this.isSelected,
    required this.onTap,
  });

  final ClothingStyle style;
  final bool isSelected;
  final void Function(ClothingStyle style) onTap;

  @override
  Widget build(final BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => onTap(style),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: StylePreferenceGrid._imageAspectRatio,
            child: AnimatedContainer(
              duration: AppDuration.standard,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outline.withValues(
                          alpha: AppOpacity.strong,
                        ),
                  width: isSelected ? AppStroke.regular : AppStroke.thin,
                ),
                borderRadius: AppRadius.cardAll,
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: AppRadius.inputAll,
                    child: Image.asset(
                      'assets/images/onboarding/${style.value}.webp',
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder:
                          (final context, final error, final stackTrace) {
                            return Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported_outlined,
                                    color: colorScheme.outline,
                                    size: 32,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    style.value,
                                    style: textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            );
                          },
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: colorScheme.onPrimary,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            style.label,
            style: textTheme.bodySmall?.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
