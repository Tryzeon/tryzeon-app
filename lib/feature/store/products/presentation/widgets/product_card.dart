import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
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

    final categoriesAsync = ref.watch(productCategoriesProvider);
    final categoryNames = categoriesAsync.maybeWhen(
      data: (final categories) {
        final Map<String, String> idToName = {
          for (final cat in categories) cat.id: cat.name,
        };
        final names = product.categoryIds.map((final id) => idToName[id] ?? id).toList();
        return names.join(' · ');
      },
      orElse: () => '',
    );

    return GestureDetector(
      onTap: () => context.push(AppRoutes.storeProductDetailPath(product.id)),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: product.imageUrls.isEmpty
                  ? Container(
                      color: colorScheme.surfaceContainerLow,
                      child: Icon(
                        Icons.image_outlined,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: product.imageUrls.first,
                      cacheKey: product.imagePaths.isNotEmpty
                          ? product.imagePaths.first
                          : null,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (final context, final url) =>
                          Container(color: colorScheme.surfaceContainerLow),
                      errorWidget: (final context, final url, final error) => Container(
                        color: colorScheme.surfaceContainerLow,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.smMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '\$${product.price.toStringAsFixed(0)}',
                    style: textTheme.titleSmall?.copyWith(color: colorScheme.primary),
                  ),
                  if (categoryNames.isNotEmpty)
                    Text(
                      categoryNames.toUpperCase(),
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  _AnalyticsRow(productId: product.id),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsRow extends ConsumerWidget {
  const _AnalyticsRow({required this.productId});

  final String productId;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final analytics = ref.watch(
      productAnalyticsSummariesProvider.select(
        (final async) =>
            async.value?.where((final s) => s.productId == productId).firstOrNull,
      ),
    );

    if (analytics == null) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AnalyticsBadge(icon: Icons.visibility_outlined, count: analytics.viewCount),
        const SizedBox(width: AppSpacing.smMd),
        _AnalyticsBadge(icon: Icons.checkroom_outlined, count: analytics.tryonCount),
        const SizedBox(width: AppSpacing.smMd),
        _AnalyticsBadge(
          icon: Icons.north_east_rounded,
          count: analytics.purchaseClickCount,
        ),
      ],
    );
  }
}

class _AnalyticsBadge extends StatelessWidget {
  const _AnalyticsBadge({required this.icon, required this.count});

  final IconData icon;
  final int count;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
