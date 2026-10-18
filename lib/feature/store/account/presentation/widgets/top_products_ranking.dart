import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tryzeon/core/extensions/count_format_extension.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/presentation/widgets/image_placeholder.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/store/account/presentation/state/top_tried_on_products.dart';
import 'package:tryzeon/feature/store/account/providers/store_account_providers.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/presentation/state/product_sort_condition.dart';
import 'package:tryzeon/feature/store/product/providers/store_product_providers.dart';

const _tabularFigures = [FontFeature.tabularFigures()];

final _skeletonItems = [
  for (var i = 0; i < 3; i++)
    (
      product: Product(
        id: '$i',
        storeId: '',
        name: '商品名稱載入中',
        categoryId: '',
        garmentType: GarmentType.top,
        price: 0,
        imagePaths: const [],
        imageUrls: const [],
        createdAt: DateTime(2000),
        updatedAt: DateTime(2000),
      ),
      tryonCount: 100 - i * 30,
    ),
];

class TopProductsRanking extends ConsumerWidget {
  const TopProductsRanking({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final topAsync = ref.watch(topTriedOnProductsProvider);
    final top = topAsync.value;
    final isLoading = top == null || topAsync.isReloading;
    final hasRanking = !topAsync.hasError && (isLoading || top.isNotEmpty);

    final Widget body;
    if (topAsync.hasError) {
      body = ErrorView(
        isCompact: true,
        onRetry: () => ref
          ..invalidate(productsProvider)
          ..invalidate(productAnalyticsSummariesProvider),
      );
    } else if (!isLoading && top.isEmpty) {
      body = Text(
        '這個月份還沒有熱門商品，分享店舖帶來更多試穿吧',
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      );
    } else {
      final items = isLoading ? _skeletonItems : top;
      final maxCount = items.first.tryonCount;
      body = Skeletonizer(
        enabled: isLoading,
        child: Column(
          children: [
            for (final (index, item) in items.indexed) ...[
              if (index > 0) const SizedBox(height: AppSpacing.smMd),
              _RankRow(rank: index + 1, item: item, maxCount: maxCount),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        '熱門商品',
                        style: textTheme.headlineSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        '依試穿',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasRanking)
                TextButton(
                  onPressed: () => _showAllByTryons(context, ref),
                  child: const Text('查看全部'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          body,
        ],
      ),
    );
  }

  void _showAllByTryons(final BuildContext context, final WidgetRef ref) {
    ref
        .read(productQueryProvider.notifier)
        .showAllSortedBy(
          SortCondition.byDefault(
            const SortKey.analytics(AnalyticsMetric.tryonCount),
          ),
        );
    context.go(AppRoutes.dashboardProducts);
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.item,
    required this.maxCount,
  });

  static const double _rankWidth = 24;
  static const double _thumbnailWidth = 48;
  static const double _barHeight = 6;
  static const double _countWidth = 48;

  final int rank;
  final RankedProduct item;
  final int maxCount;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final product = item.product;

    return InkWell(
      onTap: () =>
          context.push(AppRoutes.dashboardProductDetailPath(product.id)),
      borderRadius: AppRadius.cardAll,
      child: Row(
        children: [
          SizedBox(
            width: _rankWidth,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '$rank',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w300,
                  fontFeatures: _tabularFigures,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: _thumbnailWidth,
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: ClipRRect(
                borderRadius: AppRadius.buttonAll,
                child: _ProductImage(product: product),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.smMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: AppRadius.pillAll,
                        child: LinearProgressIndicator(
                          value: item.tryonCount / maxCount,
                          minHeight: _barHeight,
                          backgroundColor: colorScheme.surfaceContainerHigh,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.smMd),
                    SizedBox(
                      width: _countWidth,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          item.tryonCount.asCount,
                          style: textTheme.labelLarge?.copyWith(
                            fontFeatures: _tabularFigures,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product});

  final Product product;

  @override
  Widget build(final BuildContext context) {
    if (product.imageUrls.isEmpty) return const ImagePlaceholder();
    return CachedNetworkImage(
      imageUrl: product.imageUrls.first,
      fit: BoxFit.cover,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      errorWidget: (final context, final url, final error) =>
          const ImagePlaceholder(),
    );
  }
}
