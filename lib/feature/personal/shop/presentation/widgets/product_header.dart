import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/presentation/actions/launch_product_purchase.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/product_image_viewer.dart';

class ProductHeader extends ConsumerWidget {
  const ProductHeader({required this.product, required this.categoryIdToName, super.key});

  final ShopProduct product;
  final Map<String, String> categoryIdToName;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final canPurchase = hasPurchaseLink(product);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Image with Zoom
        ProductImageViewer(imageUrls: product.imageUrls, imagePaths: product.imagePaths),

        Padding(
          padding: const EdgeInsets.all(AppSpacing.mdLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Category and Styles
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  // Product Categories
                  ...product.categoryIds.map(
                    (final categoryId) => Chip(
                      label: Text(
                        categoryIdToName[categoryId] ?? categoryId,
                        style: textTheme.labelMedium,
                      ),
                    ),
                  ),

                  // Product Styles
                  if (product.styles != null && product.styles!.isNotEmpty)
                    ...product.styles!.map(
                      (final style) =>
                          Chip(label: Text(style.label, style: textTheme.labelMedium)),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.smMd),

              // Product Name
              Text(product.name, style: textTheme.headlineLarge),
              const SizedBox(height: AppSpacing.sm),

              // Price
              Text(
                '\$${product.price}',
                style: textTheme.titleLarge?.copyWith(color: colorScheme.primary),
              ),

              // Purchase link
              if (canPurchase) ...[
                InkWell(
                  onTap: () => launchProductPurchase(context, ref, product),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '前往購買',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Icon(Icons.open_in_new, size: 14, color: colorScheme.primary),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
