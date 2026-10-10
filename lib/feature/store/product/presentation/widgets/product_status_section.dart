import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/presentation/actions/toggle_product_status.dart';
import 'package:tryzeon/feature/store/product/presentation/mappers/product_status_ui_mapper.dart';

class ProductStatusSection extends StatelessWidget {
  const ProductStatusSection({
    super.key,
    required this.product,
    this.isBusy = false,
    this.isUpdating = false,
  });

  final Product product;
  final bool isBusy;
  final bool isUpdating;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final status = product.status;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xl),
        const Divider(),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '商品狀態',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.smMd),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(status.tabLabel, style: textTheme.titleSmall),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          status.description,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  OutlinedButton(
                    onPressed: isBusy
                        ? null
                        : () => toggleProductStatus(context, product),
                    child: isUpdating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: AppStroke.regular,
                            ),
                          )
                        : Text(status.toggleLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
