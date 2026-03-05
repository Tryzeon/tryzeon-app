import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';

class MonthFilterWidget extends HookConsumerWidget {
  const MonthFilterWidget({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final filter = ref.watch(storeAnalyticsFilterProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
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
                    filter == null ? '全部時間' : '${filter.year}年 ${filter.month}月',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
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
              onPressed: _canGoNextMonth(filter) ? () => _onNextMonth(ref, filter) : null,
            ),
            Container(
              width: 1,
              height: 20,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
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
    );
  }

  void _onPreviousMonth(final WidgetRef ref, final ({int year, int month})? filter) {
    final now = DateTime.now();
    if (filter == null) {
      ref.read(storeAnalyticsFilterProvider.notifier).filter = (
        year: now.year,
        month: now.month,
      );
    } else {
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

  void _onNextMonth(final WidgetRef ref, final ({int year, int month})? filter) {
    final now = DateTime.now();
    if (filter == null) {
      ref.read(storeAnalyticsFilterProvider.notifier).filter = (
        year: now.year,
        month: now.month,
      );
    } else {
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

  void _onAllTime(final WidgetRef ref) {
    ref.read(storeAnalyticsFilterProvider.notifier).filter = null;
  }

  bool _canGoNextMonth(final ({int year, int month})? filter) {
    if (filter == null) return true;
    final now = DateTime.now();
    return !(filter.year == now.year && filter.month == now.month);
  }
}
