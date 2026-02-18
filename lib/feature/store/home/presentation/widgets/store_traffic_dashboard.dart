import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';

class StoreTrafficDashboard extends HookConsumerWidget {
  const StoreTrafficDashboard({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final analyticsAsync = ref.watch(storeAnalyticsSummaryProvider);
    final filter = ref.watch(storeAnalyticsFilterProvider);

    final colorScheme = Theme.of(context).colorScheme;

    // Calculate stats
    int totalView = 0;
    int totalTryOn = 0;
    int totalPurchaseClicks = 0;
    bool hasError = false;

    if (analyticsAsync.hasValue && analyticsAsync.value != null) {
      totalView = analyticsAsync.value!.viewCount;
      totalTryOn = analyticsAsync.value!.tryonCount;
      totalPurchaseClicks = analyticsAsync.value!.purchaseClickCount;
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
          // 第一行：標題
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
          const SizedBox(height: 16),
          // 第二行：月份篩選器
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 左箭頭：上一個月
                      IconButton(
                        icon: Icon(
                          Icons.chevron_left_rounded,
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        tooltip: '上一個月',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () => _onPreviousMonth(ref, filter),
                      ),
                      // 中間顯示區域
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              color: colorScheme.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              filter == null
                                  ? '全部時間'
                                  : '${filter.year}年 ${filter.month}月',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ],
                        ),
                      ),
                      // 右箭頭：下一個月（不能超過當前月份）
                      IconButton(
                        icon: Icon(
                          Icons.chevron_right_rounded,
                          color: _canGoNextMonth(filter)
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                          size: 20,
                        ),
                        tooltip: '下一個月',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: _canGoNextMonth(filter)
                            ? () => _onNextMonth(ref, filter)
                            : null,
                      ),
                      // 分隔線
                      Container(
                        width: 1,
                        height: 20,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                      // "全部時間"按鈕
                      IconButton(
                        icon: Icon(
                          Icons.all_inclusive_rounded,
                          color: filter == null
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          size: 16,
                        ),
                        tooltip: '全部時間',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () => _onAllTime(ref),
                      ),
                    ],
                  ),
                ),
              ),
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

  /// 切換到上一個月
  void _onPreviousMonth(final WidgetRef ref, final ({int year, int month})? filter) {
    final now = DateTime.now();
    if (filter == null) {
      // 從全部時間切換到當前月份
      ref.read(storeAnalyticsFilterProvider.notifier).filter = (
        year: now.year,
        month: now.month,
      );
    } else {
      // 往前一個月
      var newYear = filter.year;
      var newMonth = filter.month - 1;
      if (newMonth < 1) {
        newYear -= 1;
        newMonth = 12;
      }
      ref.read(storeAnalyticsFilterProvider.notifier).filter = (
        year: newYear,
        month: newMonth,
      );
    }
  }

  /// 切換到下一個月
  void _onNextMonth(final WidgetRef ref, final ({int year, int month})? filter) {
    final now = DateTime.now();
    if (filter == null) {
      // 從全部時間切換到當前月份
      ref.read(storeAnalyticsFilterProvider.notifier).filter = (
        year: now.year,
        month: now.month,
      );
    } else {
      // 往後一個月
      var newYear = filter.year;
      var newMonth = filter.month + 1;
      if (newMonth > 12) {
        newYear += 1;
        newMonth = 1;
      }
      ref.read(storeAnalyticsFilterProvider.notifier).filter = (
        year: newYear,
        month: newMonth,
      );
    }
  }

  /// 切換到全部時間
  void _onAllTime(final WidgetRef ref) {
    ref.read(storeAnalyticsFilterProvider.notifier).filter = null;
  }

  /// 檢查是否可以前往下一個月（不能超過當前月份）
  bool _canGoNextMonth(final ({int year, int month})? filter) {
    if (filter == null) return true; // 從全部時間可以切換到當前月份

    final now = DateTime.now();
    // 如果當前選擇的月份是當前月份，則不能再往後
    if (filter.year == now.year && filter.month == now.month) {
      return false;
    }
    return true;
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
