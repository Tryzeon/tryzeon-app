import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class ProductDescriptionSection extends StatelessWidget {
  const ProductDescriptionSection({required this.description, super.key});

  final String description;

  @override
  Widget build(final BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('商品描述', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.smMd),
        Text(description, style: textTheme.bodyMedium),
      ],
    );
  }
}
