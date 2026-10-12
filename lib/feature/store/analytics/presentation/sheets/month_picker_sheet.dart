import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/widgets/app_sheet.dart';
import 'package:tryzeon/feature/store/analytics/presentation/state/analytics_months.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';

class MonthPickerSheet extends ConsumerWidget {
  const MonthPickerSheet({super.key});

  static Future<void> show(final BuildContext context) {
    return showAppSheet<void>(
      context: context,
      builder: (final _) => const MonthPickerSheet(),
    );
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final selected = ref.watch(storeAnalyticsFilterProvider);
    final openedAt = ref.watch(storeProfileProvider).value?.createdAt;
    final colorScheme = Theme.of(context).colorScheme;

    final months = analyticsMonthsSince(openedAt, now: DateTime.now());

    return AppSheet(
      title: '選擇月份',
      height: AppSheetHeight.tall,
      body: ListView.builder(
        itemCount: months.length,
        itemBuilder: (final _, final index) {
          final month = months[index];
          return ListTile(
            title: Text(month.label),
            selected: month == selected,
            trailing: month == selected
                ? Icon(Icons.check_rounded, color: colorScheme.primary)
                : null,
            onTap: () {
              ref.read(storeAnalyticsFilterProvider.notifier).filter = month;
              Navigator.of(context).pop();
            },
          );
        },
      ),
    );
  }
}
