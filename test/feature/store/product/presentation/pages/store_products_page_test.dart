import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';
import 'package:tryzeon/feature/store/product/presentation/pages/store_products_page.dart';
import 'package:tryzeon/feature/store/product/presentation/state/product_sort_condition.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/product_search_bar.dart';
import 'package:tryzeon/feature/store/product/providers/store_product_providers.dart';

import '../../../../../support/store_test_doubles.dart';

void main() {
  testWidgets('pull-to-refresh reloads both products and analytics summaries', (
    final tester,
  ) async {
    final products = FakeProducts();
    final analytics = FakeAnalyticsSummaries();
    final container = ProviderContainer(
      overrides: [
        productsProvider.overrideWith(() => products),
        productAnalyticsSummariesProvider.overrideWith(() => analytics),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const StoreProductsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await pullToRefresh(tester, find.byType(CustomScrollView));

    expect(products.refreshCount, 1);
    expect(analytics.refreshCount, 1);
  });

  testWidgets('the sort button names the current field and direction', (
    final tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        productsProvider.overrideWith(FakeProducts.new),
        productAnalyticsSummariesProvider.overrideWith(
          FakeAnalyticsSummaries.new,
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const StoreProductsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('建立時間 · 新 → 舊'), findsOneWidget);

    container
        .read(productQueryProvider.notifier)
        .updateSort(
          const SortCondition(
            key: SortKey.product(ProductField.price),
            ascending: true,
          ),
        );
    await tester.pump();

    expect(find.text('價格 · 低 → 高'), findsOneWidget);
  });

  group('scrolling the product grid', () {
    late ProviderContainer container;

    Future<void> pumpPage(final WidgetTester tester) async {
      container = ProviderContainer(
        overrides: [
          productsProvider.overrideWith(
            () => FakeProducts([
              for (var i = 0; i < 20; i++) product('active $i'),
              for (var i = 0; i < 20; i++)
                product('archived $i', status: ProductStatus.archived),
            ]),
          ),
          productAnalyticsSummariesProvider.overrideWith(
            FakeAnalyticsSummaries.new,
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const StoreProductsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> scrollDown(final WidgetTester tester) async {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();
    }

    final searchBar = find.byType(ProductSearchBar).hitTestable();
    double tabsTop(final WidgetTester tester) =>
        tester.getTopLeft(find.byType(TabBar)).dy;

    testWidgets('hides the search bar but keeps the status tabs pinned', (
      final tester,
    ) async {
      await pumpPage(tester);
      expect(searchBar, findsOneWidget);

      await scrollDown(tester);

      expect(searchBar, findsNothing);
      expect(tabsTop(tester), 0);
    });

    testWidgets('brings the search bar back on a short upward scroll', (
      final tester,
    ) async {
      await pumpPage(tester);
      await scrollDown(tester);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, 40));
      await tester.pumpAndSettle();

      expect(searchBar, findsOneWidget);
      expect(
        tabsTop(tester),
        tester.getBottomLeft(find.byType(ProductSearchBar)).dy + AppSpacing.sm,
      );
    });

    testWidgets(
      'switching status starts the list from the top with the tabs pinned',
      (final tester) async {
        await pumpPage(tester);
        await scrollDown(tester);
        await scrollDown(tester);

        container
            .read(productQueryProvider.notifier)
            .updateStatus(ProductStatus.archived);
        await tester.pumpAndSettle();

        expect(find.text('archived 0'), findsOneWidget);
        expect(searchBar, findsNothing);
        expect(tabsTop(tester), 0);
      },
    );
  });
}
