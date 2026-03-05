import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/common/product_categories/providers/product_categories_providers.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';

class StoreProductCard extends HookConsumerWidget {
  const StoreProductCard({super.key, required this.product});
  final Product product;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Build category ID to name mapping
    final categoriesAsync = ref.watch(productCategoriesProvider);
    final categoryNames = categoriesAsync.maybeWhen(
      data: (final categories) {
        final Map<String, String> idToName = {
          for (final cat in categories) cat.id: cat.name,
        };
        return product.categories
            .map((final id) => idToName[id] ?? id)
            .where((final name) => name.isNotEmpty)
            .join(', ');
      },
      orElse: () => '',
    );

    return GestureDetector(
      onTap: () {
        context.push('/store/products/${product.id}', extra: product);
      },
      child: Card(
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    cacheKey: product.imagePath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (final context, final url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (final context, final url, final error) =>
                        const Center(child: Icon(Icons.error_outline)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    categoryNames,
                    style: textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${product.price}',
                    style: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
                  ),
                  const SizedBox(height: 4),

                  // Analytics badges
                  _buildAnalyticsBadges(ref, textTheme),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsBadges(final WidgetRef ref, final TextTheme textTheme) {
    final analyticsMap = ref.watch(productAnalyticsMapProvider);
    final analytics = analyticsMap[product.id];

    if (analytics == null) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        _buildBadge(
          icon: Icons.visibility_outlined,
          count: analytics.viewCount,
          textTheme: textTheme,
        ),
        _buildBadge(
          icon: Icons.checkroom_outlined,
          count: analytics.tryonCount,
          textTheme: textTheme,
        ),
        _buildBadge(
          icon: Icons.shopping_cart_outlined,
          count: analytics.purchaseClickCount,
          textTheme: textTheme,
        ),
      ],
    );
  }

  Widget _buildBadge({
    required final IconData icon,
    required final int count,
    required final TextTheme textTheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade700),
          const SizedBox(width: 2),
          Text(
            count.toString(),
            style: textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
