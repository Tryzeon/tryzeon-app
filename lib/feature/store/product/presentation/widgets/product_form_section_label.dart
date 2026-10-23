import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class ProductFormSectionLabel extends StatelessWidget {
  const ProductFormSectionLabel({
    super.key,
    required this.number,
    required this.title,
    this.helper,
  });

  final String number;
  final String title;
  final String? helper;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          number,
          style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurface),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(title, style: textTheme.titleMedium),
        if (helper != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            helper!,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
