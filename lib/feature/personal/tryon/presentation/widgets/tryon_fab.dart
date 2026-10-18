import 'package:flutter/material.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_anchor.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_target.dart';
import 'package:tryzeon/core/presentation/widgets/glass_pill.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class TryonFab extends StatelessWidget {
  const TryonFab({
    super.key,
    required this.onTap,
    this.label,
    this.icon,
    this.coachMarkTarget,
    this.compact = false,
  });

  final VoidCallback onTap;
  final String? label;
  final IconData? icon;

  /// For a pill laid over a small photo, where the regular one would cover
  /// half of it. The tap area shrinks to the pill so it does not push the
  /// text beside it apart; a miss lands on the photo's own tap target.
  final bool compact;

  /// Anchors a coach mark on the visible pill, not the larger tap area.
  final CoachMarkTarget? coachMarkTarget;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: compact
            ? const BoxConstraints()
            : const BoxConstraints(
                minWidth: kMinInteractiveDimension,
                minHeight: kMinInteractiveDimension,
              ),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: switch (coachMarkTarget) {
            final target? => CoachMarkAnchor(
              target: target,
              child: _buildPill(colorScheme, textTheme),
            ),
            null => _buildPill(colorScheme, textTheme),
          },
        ),
      ),
    );
  }

  Widget _buildPill(final ColorScheme colorScheme, final TextTheme textTheme) {
    final iconSize = compact ? 16.0 : 24.0;
    const vertical = AppSpacing.sm;
    final horizontal = compact ? AppSpacing.sm : AppSpacing.smMd;
    return GlassPill(
      padding: label == null
          ? const EdgeInsets.all(vertical)
          : EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon == null
              ? Image.asset(
                  AppConstants.logoMark,
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.contain,
                )
              : Icon(icon, size: iconSize, color: colorScheme.onPrimary),
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
    );
  }
}
