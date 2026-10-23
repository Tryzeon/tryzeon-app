import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_anchor.dart';
import 'package:tryzeon/core/presentation/coach_mark/coach_mark_target.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/account/presentation/widgets/store_performance_section.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/analytics_month.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/product_analytics_summary.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/store_traffic_totals.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';

import '../../../../../support/store_test_doubles.dart';

final _october = [summary('a', views: 1000, tryons: 180, clicks: 90)];

Future<ProviderContainer> pump(
  final WidgetTester tester, {
  required final List<Override> overrides,
}) async {
  final container = ProviderContainer(
    retry: (final _, final _) => null,
    overrides: overrides,
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: StorePerformanceSection()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> pumpTotals(
  final WidgetTester tester,
  final Future<StoreTrafficTotals> Function() load,
) => pump(
  tester,
  overrides: [storeTrafficTotalsProvider.overrideWith((final ref) => load())],
);

Future<ProviderContainer> pumpMonths(
  final WidgetTester tester,
  final Future<List<ProductAnalyticsSummary>> Function(AnalyticsMonth month)
  load,
) => pump(
  tester,
  overrides: [
    productAnalyticsSummariesProvider.overrideWith(
      () => FakeAnalyticsSummaries(load),
    ),
  ],
);

void main() {
  testWidgets('shows totals and view-based rates', (final tester) async {
    await pumpTotals(
      tester,
      () async => const StoreTrafficTotals(
        viewCount: 1000,
        tryonCount: 180,
        purchaseClickCount: 90,
      ),
    );

    expect(find.text('180'), findsOneWidget);
    expect(find.text('瀏覽的 18% 進行試穿'), findsOneWidget);
    expect(find.text('1,000'), findsOneWidget);
    expect(find.text('90 9%'), findsOneWidget);
  });

  testWidgets('without views there is no rate, only the empty caption', (
    final tester,
  ) async {
    await pumpTotals(
      tester,
      () async => const StoreTrafficTotals(
        viewCount: 0,
        tryonCount: 0,
        purchaseClickCount: 0,
      ),
    );

    expect(find.textContaining('進行試穿'), findsNothing);
    expect(find.text('這個月份還沒有瀏覽紀錄'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('a try-on rate above 100% is shown as-is', (final tester) async {
    await pumpTotals(
      tester,
      () async => const StoreTrafficTotals(
        viewCount: 100,
        tryonCount: 150,
        purchaseClickCount: 0,
      ),
    );

    expect(find.text('瀏覽的 150% 進行試穿'), findsOneWidget);
  });

  testWidgets('huge counts fit a 320pt screen', (final tester) async {
    useNarrowScreen(tester);
    await pumpTotals(
      tester,
      () async => const StoreTrafficTotals(
        viewCount: 123456789,
        tryonCount: 12345678,
        purchaseClickCount: 1234567,
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed load shows a compact error', (final tester) async {
    await pumpTotals(tester, () async => throw const UnknownFailure('boom'));

    expect(find.byType(ErrorView), findsOneWidget);
  });

  testWidgets('a month still loading does not show the previous month', (
    final tester,
  ) async {
    final pending = Completer<List<ProductAnalyticsSummary>>();
    final container = await pumpMonths(
      tester,
      (final month) =>
          month == currentMonth ? Future.value(_october) : pending.future,
    );
    expect(find.text('180'), findsOneWidget);

    showPreviousMonth(container);
    await tester.pump();
    expect(find.text('180'), findsNothing);
    expect(find.text('10,000'), findsOneWidget);

    pending.complete(const []);
    await tester.pumpAndSettle();
    expect(find.text('10,000'), findsNothing);
    expect(find.text('這個月份還沒有瀏覽紀錄'), findsOneWidget);
  });

  testWidgets('a failed month switch shows an error, not the old month', (
    final tester,
  ) async {
    final container = await pumpMonths(
      tester,
      (final month) => month == currentMonth
          ? Future.value(_october)
          : Future.error(const UnknownFailure('offline')),
    );

    showPreviousMonth(container);
    await tester.pumpAndSettle();

    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('180'), findsNothing);
  });

  testWidgets('the coach-mark target is the card, not its page padding', (
    final tester,
  ) async {
    await pumpTotals(
      tester,
      () async => const StoreTrafficTotals(
        viewCount: 10,
        tryonCount: 1,
        purchaseClickCount: 0,
      ),
    );

    final anchor = tester.getRect(
      find.byWidgetPredicate(
        (final w) =>
            w is CoachMarkAnchor &&
            w.target == CoachMarkTarget.storePerformance,
      ),
    );
    expect(anchor.left, AppSpacing.lg);
    expect(anchor.right, 800 - AppSpacing.lg);
  });
}
