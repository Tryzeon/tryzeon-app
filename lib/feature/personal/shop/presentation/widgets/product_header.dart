import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/product_image_viewer.dart';

class ProductHeader extends StatelessWidget {
  const ProductHeader({required this.product, required this.categoryIdToName, super.key});

  final ShopProduct product;
  final Map<String, String> categoryIdToName;

  @override
  Widget build(final BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
                style: textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
