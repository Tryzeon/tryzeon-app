import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';

class StoreTrafficDashboard extends HookConsumerWidget {
  const StoreTrafficDashboard({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final analyticsAsync = ref.watch(productAnalyticsSummariesProvider);

    final colorScheme = Theme.of(context).colorScheme;

    int totalView = 0;
    int totalTryOn = 0;
    int totalPurchaseClicks = 0;
    bool hasError = false;

    if (analyticsAsync.hasValue && analyticsAsync.value != null) {
      for (final s in analyticsAsync.value!) {
        totalView += s.viewCount;
        totalTryOn += s.tryonCount;
        totalPurchaseClicks += s.purchaseClickCount;
      }
    } else if (analyticsAsync.hasError) {
      hasError = true;
    }

    final isLoading = analyticsAsync.isLoading;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('總流量概況', style: Theme.of(context).textTheme.titleMedium),
              if (hasError) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: '資料載入失敗，請下拉刷新',
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: colorScheme.error,
                    size: 16,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _StatItem(
                label: '瀏覽次數',
                value: isLoading ? 8888 : totalView,
                icon: Icons.visibility_rounded,
                isLoading: isLoading,
                hasError: hasError,
              ),
              Container(
                width: 1,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              _StatItem(
                label: '虛擬試穿',
                value: isLoading ? 8888 : totalTryOn,
                icon: Icons.checkroom_rounded,
                isLoading: isLoading,
                hasError: hasError,
              ),
              Container(
                width: 1,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              _StatItem(
                label: '購買點擊',
                value: isLoading ? 8888 : totalPurchaseClicks,
                icon: Icons.ads_click_rounded,
                isLoading: isLoading,
                hasError: hasError,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.isLoading,
    required this.hasError,
  });

  final String label;
  final int value;
  final IconData icon;
  final bool isLoading;
  final bool hasError;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colorScheme.onSurfaceVariant, size: 14),
              const SizedBox(width: 6),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          Skeletonizer(
            enabled: isLoading,
            child: Text(
              hasError ? '--' : value.toString(),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: hasError ? colorScheme.onSurfaceVariant : colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
