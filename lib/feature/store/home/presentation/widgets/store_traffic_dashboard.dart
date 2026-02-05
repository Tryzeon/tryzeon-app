import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      totalView = analyticsAsync.value!.totalViewCount;
      totalTryOn = analyticsAsync.value!.totalTryonCount;
      totalPurchaseClicks = analyticsAsync.value!.totalPurchaseClickCount;
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
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.auto_graph_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '總流量概況',
                      style: GoogleFonts.outfit(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
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
              ),
              // 月份篩選器
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
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(32),
                  clipBehavior: Clip.antiAlias,
                  child: PopupMenuButton<({int year, int month})>(
                    initialValue: filter ?? (year: 0, month: 0),
                    tooltip: '篩選月份',
                    elevation: 3,
                    shadowColor: Colors.black.withValues(alpha: 0.2),
                    surfaceTintColor: colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.05),
                      ),
                    ),
                    position: PopupMenuPosition.under,
                    offset: const Offset(0, 8),
                    onSelected: (final value) {
                      if (value.year == 0 && value.month == 0) {
                        ref.read(storeAnalyticsFilterProvider.notifier).state = null;
                      } else {
                        ref.read(storeAnalyticsFilterProvider.notifier).state = value;
                      }
                    },
                    itemBuilder: (final context) {
                      final now = DateTime.now();
                      final currentYear = now.year;
                      final currentMonth = now.month;

                      return [
                        // 選項：全部時間
                        PopupMenuItem(
                          value: const (year: 0, month: 0),
                          height: 48,
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 18,
                                color: filter == null
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '全部時間',
                                style: GoogleFonts.outfit(
                                  fontWeight: filter == null
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: filter == null
                                      ? colorScheme.primary
                                      : colorScheme.onSurface,
                                ),
                              ),
                              if (filter == null) ...[
                                const Spacer(),
                                Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: colorScheme.primary,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        // 選項：過去 6 個月
                        for (int i = 0; i < 6; i++)
                          _buildMonthItem(context, currentYear, currentMonth, i, filter),
                      ];
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            filter == null ? '全部時間' : '${filter.year}年 ${filter.month}月',
                            style: GoogleFonts.outfit(
                              color: colorScheme.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
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

  PopupMenuItem<({int month, int year})> _buildMonthItem(
    final BuildContext context,
    final int currentYear,
    final int currentMonth,
    final int offset,
    final ({int year, int month})? currentFilter,
  ) {
    var y = currentYear;
    var m = currentMonth - offset;
    if (m <= 0) {
      y -= 1;
      m += 12;
    }

    final isSelected =
        currentFilter != null && currentFilter.year == y && currentFilter.month == m;
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuItem(
      value: (year: y, month: m),
      height: 48,
      child: Row(
        children: [
          Icon(
            Icons.calendar_month_outlined,
            size: 18,
            color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Text(
            '$y年 $m月',
            style: GoogleFonts.outfit(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(Icons.check_rounded, size: 18, color: colorScheme.primary),
          ],
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
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Skeletonizer(
            enabled: isLoading,
            child: Text(
              hasError ? '--' : value.toString(),
              style: GoogleFonts.outfit(
                color: hasError ? colorScheme.onSurfaceVariant : colorScheme.primary,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
