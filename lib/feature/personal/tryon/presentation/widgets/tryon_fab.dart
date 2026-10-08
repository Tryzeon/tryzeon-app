import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class TryonFab extends StatelessWidget {
  const TryonFab({super.key, required this.onTap, this.label, this.icon});

  static const double _iconSize = 24;

  final VoidCallback onTap;
  final String? label;
  final IconData? icon;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: kMinInteractiveDimension,
          minHeight: kMinInteractiveDimension,
        ),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: _buildPill(colorScheme, textTheme),
        ),
      ),
    );
  }

  Widget _buildPill(final ColorScheme colorScheme, final TextTheme textTheme) {
    return ClipRRect(
      borderRadius: AppRadius.pillAll,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: label == null
              ? const EdgeInsets.all(AppSpacing.sm)
              : const EdgeInsets.symmetric(
                  horizontal: AppSpacing.smMd,
                  vertical: AppSpacing.sm,
                ),
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: AppOpacity.overlay),
            border: Border.all(
              color: colorScheme.onPrimary.withValues(alpha: AppOpacity.medium),
              width: AppStroke.thin,
            ),
            borderRadius: AppRadius.pillAll,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon == null
                  ? Image.asset(
                      AppConstants.logoMark,
                      width: _iconSize,
                      height: _iconSize,
                      fit: BoxFit.contain,
                    )
                  : Icon(icon, size: _iconSize, color: colorScheme.onPrimary),
              if (label != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label!,
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onPrimary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
