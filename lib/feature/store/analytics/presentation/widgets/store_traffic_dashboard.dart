import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tryzeon/core/extensions/count_format_extension.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/product_analytics_summary.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';

class StoreTrafficDashboard extends HookConsumerWidget {
  const StoreTrafficDashboard({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final analyticsAsync = ref.watch(productAnalyticsSummariesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final summaries = analyticsAsync.value;
    final isLoading = summaries == null && analyticsAsync.isLoading;

    var totalView = 0;
    var totalTryon = 0;
    var totalPurchaseClicks = 0;
    for (final s in summaries ?? _skeletonSummaries(isLoading)) {
      totalView += s.viewCount;
      totalTryon += s.tryonCount;
      totalPurchaseClicks += s.purchaseClickCount;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.mdLg),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colorScheme.outline),
          bottom: BorderSide(color: colorScheme.outline),
        ),
      ),
      child: summaries == null && analyticsAsync.hasError
          ? ErrorView(
              isCompact: true,
              onRetry: () => ref.invalidate(productAnalyticsSummariesProvider),
            )
          : Row(
              children: [
                _TrafficStatTile(
                  label: '瀏覽',
                  value: totalView,
                  isLoading: isLoading,
                ),
                _TrafficStatTile(
                  label: '試穿',
                  value: totalTryon,
                  isLoading: isLoading,
                ),
                _TrafficStatTile(
                  label: '購買點擊',
                  value: totalPurchaseClicks,
                  isLoading: isLoading,
                ),
              ],
            ),
    );
  }
}

List<ProductAnalyticsSummary> _skeletonSummaries(final bool isLoading) =>
    isLoading
    ? const [
        ProductAnalyticsSummary(
          productId: '',
          viewCount: 100,
          tryonCount: 100,
          purchaseClickCount: 100,
        ),
      ]
    : const [];

class _TrafficStatTile extends StatelessWidget {
  const _TrafficStatTile({
    required this.label,
    required this.value,
    required this.isLoading,
  });

  final String label;
  final int value;
  final bool isLoading;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeletonizer(
            enabled: isLoading,
            child: Text(value.asCount, style: textTheme.headlineLarge),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
