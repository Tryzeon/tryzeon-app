import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tryzeon/core/extensions/count_format_extension.dart';
import 'package:tryzeon/core/extensions/percent_format_extension.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/store_traffic_totals.dart';
import 'package:tryzeon/feature/store/analytics/presentation/widgets/month_filter_widget.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';

const _tabularFigures = [FontFeature.tabularFigures()];

class StorePerformanceSection extends ConsumerWidget {
  const StorePerformanceSection({super.key});

  static const _skeletonTotals = StoreTrafficTotals(
    viewCount: 10000,
    tryonCount: 1000,
    purchaseClickCount: 100,
  );

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final totalsAsync = ref.watch(storeTrafficTotalsProvider);
    final totals = totalsAsync.value;

    if (totalsAsync.hasError) {
      return ErrorView(
        isCompact: true,
        onRetry: () => ref.invalidate(productAnalyticsSummariesProvider),
      );
    }

    final isLoading = totals == null || totalsAsync.isReloading;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: _PerformanceCard(
        totals: isLoading ? _skeletonTotals : totals,
        isLoading: isLoading,
      ),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({required this.totals, required this.isLoading});

  final StoreTrafficTotals totals;
  final bool isLoading;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final mutedStyle = textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );
    final tryonRate = totals.tryonRate;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.mdLg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: colorScheme.onSurface),
      ),
      child: Skeletonizer(
        enabled: isLoading,
        ignorePointers: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _MetricLabel('試穿'),
                      const SizedBox(height: AppSpacing.sm),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          totals.tryonCount.asCount,
                          style: textTheme.displayLarge?.copyWith(
                            fontSize: 44,
                            fontWeight: FontWeight.w300,
                            height: 1,
                            letterSpacing: -1,
                            fontFeatures: _tabularFigures,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Skeleton.keep(child: MonthFilterWidget()),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (tryonRate != null)
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: '瀏覽的 '),
                    TextSpan(
                      text: tryonRate.asPercent,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(text: ' 進行試穿'),
                  ],
                ),
                style: mutedStyle,
              )
            else
              Text('這個月份還沒有瀏覽紀錄', style: mutedStyle),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _Metric(label: '瀏覽', value: totals.viewCount),
                  ),
                  const VerticalDivider(width: AppSpacing.xl),
                  Expanded(
                    child: _Metric(
                      label: '購買點擊',
                      value: totals.purchaseClickCount,
                      rate: totals.purchaseClickRate,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricLabel extends StatelessWidget {
  const _MetricLabel(this.label);

  final String label;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      label,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.rate});

  final String label;
  final int value;
  final double? rate;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final rate = this.rate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricLabel(label),
        const SizedBox(height: AppSpacing.xs),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: value.asCount),
                if (rate != null)
                  TextSpan(
                    text: ' ${rate.asPercent}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
              ],
            ),
            style: textTheme.displayLarge?.copyWith(
              fontSize: 24,
              letterSpacing: -0.5,
              fontFeatures: _tabularFigures,
            ),
          ),
        ),
      ],
    );
  }
}
