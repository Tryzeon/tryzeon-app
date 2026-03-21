import 'package:flutter/material.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/product_image_viewer.dart';

class ProductHeader extends StatelessWidget {
  const ProductHeader({required this.product, required this.categoryIdToName, super.key});

  final ShopProduct product;
  final Map<String, String> categoryIdToName;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Image with Zoom
        ProductImageViewer(imageUrl: product.imageUrl, imagePath: product.imagePath),

        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Category and Styles
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Product Categories
                  ...product.categoryIds.map(
                    (final categoryId) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        categoryIdToName[categoryId] ?? categoryId,
                        style: textTheme.labelMedium,
                      ),
                    ),
                  ),

                  // Product Styles
                  if (product.styles != null && product.styles!.isNotEmpty)
                    ...product.styles!.map(
                      (final style) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(style.label, style: textTheme.labelMedium),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Product Name
              Text(product.name, style: textTheme.headlineSmall),
              const SizedBox(height: 8),

              // Price
              Text('\$${product.price}', style: textTheme.titleLarge),
            ],
          ),
        ),
      ],
    );
  }
}
