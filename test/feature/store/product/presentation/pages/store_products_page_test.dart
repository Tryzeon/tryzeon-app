import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/product_analytics_summary.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/presentation/pages/store_products_page.dart';
import 'package:tryzeon/feature/store/product/presentation/state/product_sort_condition.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/product_list_section.dart';
import 'package:tryzeon/feature/store/product/providers/store_product_providers.dart';
import 'package:typed_result/typed_result.dart';

class _FakeProducts extends ProductsNotifier {
  int refreshCount = 0;

  @override
  Future<List<Product>> build() async => const [];

  @override
  Future<Result<void, Failure>> refresh() async {
    refreshCount++;
    return const Ok(null);
  }
}

class _FakeAnalytics extends ProductAnalyticsSummariesNotifier {
  int refreshCount = 0;

  @override
  Future<List<ProductAnalyticsSummary>> build() async => const [];

  @override
  Future<Result<void, Failure>> refresh() async {
    refreshCount++;
    return const Ok(null);
  }
}

Future<void> _pullToRefresh(final WidgetTester tester) async {
  await tester.fling(
    find.byType(ProductListSection),
    const Offset(0, 300),
    1000,
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('pull-to-refresh reloads both products and analytics summaries', (
    final tester,
  ) async {
    final products = _FakeProducts();
    final analytics = _FakeAnalytics();
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

    await _pullToRefresh(tester);

    expect(products.refreshCount, 1);
    expect(analytics.refreshCount, 1);
  });

  testWidgets('the sort button names the current field and direction', (
    final tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        productsProvider.overrideWith(_FakeProducts.new),
        productAnalyticsSummariesProvider.overrideWith(_FakeAnalytics.new),
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
