import 'package:flutter/material.dart';
import 'package:tryzeon/core/presentation/widgets/glass_pill.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class HomePrimaryActionButton extends StatelessWidget {
  const HomePrimaryActionButton({
    super.key,
    required this.onTap,
    required this.label,
    required this.icon,
    this.isDisabled = false,
  });

  final VoidCallback? onTap;
  final bool isDisabled;
  final String label;
  final Widget icon;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Opacity(
        opacity: isDisabled ? AppOpacity.strong : 1.0,
        child: GlassPill(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
