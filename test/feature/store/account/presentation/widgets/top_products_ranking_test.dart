import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/account/presentation/state/top_tried_on_products.dart';
import 'package:tryzeon/feature/store/account/presentation/widgets/top_products_ranking.dart';
import 'package:tryzeon/feature/store/account/providers/store_account_providers.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/analytics_month.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/product_analytics_summary.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';
import 'package:tryzeon/feature/store/product/presentation/state/product_sort_condition.dart';
import 'package:tryzeon/feature/store/product/providers/store_product_providers.dart';

import '../../../../../support/store_test_doubles.dart';

final _october = [summary('亞麻寬版襯衫', views: 10, tryons: 5)];

Future<ProviderContainer> pumpMonths(
  final WidgetTester tester,
  final Future<List<ProductAnalyticsSummary>> Function(AnalyticsMonth month)
  load,
) async {
  final container = ProviderContainer(
    retry: (final _, final _) => null,
    overrides: [
      productsProvider.overrideWith(() => FakeProducts([product('亞麻寬版襯衫')])),
      productAnalyticsSummariesProvider.overrideWith(
        () => FakeAnalyticsSummaries(load),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: SingleChildScrollView(child: TopProductsRanking()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> pump(
  final WidgetTester tester,
  final Future<List<RankedProduct>> Function() load, {
  final double textScale = 1,
}) async {
  useNarrowScreen(tester);

  await tester.pumpWidget(
    ProviderScope(
      retry: (final _, final _) => null,
      overrides: [
        topTriedOnProductsProvider.overrideWith((final ref) => load()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (final context, final child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const Scaffold(
          body: SingleChildScrollView(child: TopProductsRanking()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows ranked rows with try-on counts', (final tester) async {
    await pump(
      tester,
      () async => [
        (product: product('亞麻寬版襯衫'), tryonCount: 412),
        (product: product('高腰直筒牛仔褲'), tryonCount: 206),
      ],
    );

    expect(find.text('熱門商品'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('亞麻寬版襯衫'), findsOneWidget);
    expect(find.text('412'), findsOneWidget);
    final bars = tester
        .widgetList<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        )
        .map((final bar) => bar.value);
    expect(bars, [1.0, 0.5]);
  });

  testWidgets('see all sorts products by try-ons and opens the products tab', (
    final tester,
  ) async {
    final container = ProviderContainer(
      retry: (final _, final _) => null,
      overrides: [
        topTriedOnProductsProvider.overrideWith(
          (final ref) async => [(product: product('亞麻寬版襯衫'), tryonCount: 5)],
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = GoRouter(
      initialLocation: AppRoutes.dashboardAccount,
      routes: [
        GoRoute(
          path: AppRoutes.dashboardAccount,
          builder: (final context, final state) => const Scaffold(
            body: SingleChildScrollView(child: TopProductsRanking()),
          ),
        ),
        GoRoute(
          path: AppRoutes.dashboardProducts,
          builder: (final context, final state) =>
              const Scaffold(body: Text('products tab')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('查看全部'));
    await tester.pumpAndSettle();

    expect(find.text('products tab'), findsOneWidget);
    expect(
      container.read(productQueryProvider).sort,
      const SortCondition(
        key: SortKey.analytics(AnalyticsMetric.tryonCount),
        ascending: false,
      ),
    );
  });

  testWidgets('an empty month hides see all', (final tester) async {
    await pump(tester, () async => const []);

    expect(find.text('查看全部'), findsNothing);
  });

  testWidgets('empty month shows the share nudge', (final tester) async {
    await pump(tester, () async => const []);

    expect(find.text('這個月份還沒有熱門商品，分享店舖帶來更多試穿吧'), findsOneWidget);
  });

  testWidgets('a failed load shows a compact error', (final tester) async {
    await pump(tester, () async => throw const UnknownFailure('boom'));

    expect(find.byType(ErrorView), findsOneWidget);
  });

  testWidgets('large text and long names do not overflow', (
    final tester,
  ) async {
    await pump(
      tester,
      () async => [
        for (var i = 0; i < 5; i++)
          (product: product('超長商品名稱' * 10 + '$i'), tryonCount: 1234567),
      ],
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('a month still loading does not show the previous ranking', (
    final tester,
  ) async {
    final pending = Completer<List<ProductAnalyticsSummary>>();
    final container = await pumpMonths(
      tester,
      (final month) =>
          month == currentMonth ? Future.value(_october) : pending.future,
    );
    expect(find.text('5'), findsOneWidget);

    showPreviousMonth(container);
    await tester.pump();
    expect(find.text('5'), findsNothing);
    expect(find.text('商品名稱載入中'), findsWidgets);

    pending.complete(const []);
    await tester.pumpAndSettle();
    expect(find.text('5'), findsNothing);
  });

  testWidgets('a failed month switch shows an error, not the old ranking', (
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
    expect(find.text('5'), findsNothing);
  });
}
