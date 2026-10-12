import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/analytics/presentation/state/analytics_months.dart';
import 'package:tryzeon/feature/store/analytics/presentation/widgets/month_filter_widget.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';

import '../../../../../support/store_test_doubles.dart';

void main() {
  Future<ProviderContainer> pump(final WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        storeProfileProvider.overrideWith(
          () => FakeStoreProfile(
            () async => storeProfile(
              createdAt: DateTime(previousMonth.year, previousMonth.month, 3),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: Center(child: MonthFilterWidget())),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('shows the selected month as an outlined chip', (
    final tester,
  ) async {
    await pump(tester);

    expect(find.widgetWithText(ActionChip, currentMonth.label), findsOneWidget);
  });

  testWidgets('picking a month applies it and closes the sheet', (
    final tester,
  ) async {
    final container = await pump(tester);

    await tester.tap(find.byType(ActionChip));
    await tester.pumpAndSettle();
    expect(find.text('選擇月份'), findsOneWidget);
    expect(find.widgetWithText(ListTile, currentMonth.label), findsOneWidget);
    expect(find.widgetWithText(ListTile, previousMonth.label), findsOneWidget);

    await tester.tap(find.widgetWithText(ListTile, previousMonth.label));
    await tester.pumpAndSettle();

    expect(container.read(storeAnalyticsFilterProvider), previousMonth);
    expect(find.text('選擇月份'), findsNothing);
    expect(
      find.widgetWithText(ActionChip, previousMonth.label),
      findsOneWidget,
    );
  });
}
