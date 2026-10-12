import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/analytics/presentation/sheets/month_picker_sheet.dart';
import 'package:tryzeon/feature/store/analytics/presentation/state/analytics_months.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';

class MonthFilterWidget extends ConsumerWidget {
  const MonthFilterWidget({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final filter = ref.watch(storeAnalyticsFilterProvider);

    return ActionChip(
      tooltip: '選擇月份',
      onPressed: () => MonthPickerSheet.show(context),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(filter.label),
          const SizedBox(width: AppSpacing.xxs),
          const Icon(Icons.expand_more_rounded, size: 16),
        ],
      ),
    );
  }
}
