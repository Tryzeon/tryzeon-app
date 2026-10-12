import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';
import 'package:tryzeon/feature/store/product/presentation/pages/store_products_page.dart';
import 'package:tryzeon/feature/store/product/presentation/state/product_sort_condition.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/product_list_section.dart';
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

    await pullToRefresh(tester, find.byType(ProductListSection));

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
}
