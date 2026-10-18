import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/product_status_tabs.dart';
import 'package:tryzeon/feature/store/product/providers/store_product_providers.dart';

import '../../../../../support/store_test_doubles.dart';

Future<ProviderContainer> pump(final WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [productsProvider.overrideWith(FakeProducts.new)],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: ProductStatusTabs()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

int selectedTab(final WidgetTester tester) =>
    tester.widget<TabBar>(find.byType(TabBar)).controller!.index;

void main() {
  testWidgets('tapping a tab selects its status', (final tester) async {
    final container = await pump(tester);

    await tester.tap(find.textContaining('已下架'));
    await tester.pumpAndSettle();

    expect(container.read(productQueryProvider).status, ProductStatus.archived);
    expect(selectedTab(tester), 1);
  });

  testWidgets('the tab indicator follows a status set elsewhere', (
    final tester,
  ) async {
    // The products branch stays alive in the shell, so the dashboard's
    // "see all" resets the query while this widget is already built.
    final container = await pump(tester);
    container
        .read(productQueryProvider.notifier)
        .updateStatus(ProductStatus.archived);
    await tester.pumpAndSettle();
    expect(selectedTab(tester), 1);

    container
        .read(productQueryProvider.notifier)
        .updateStatus(ProductStatus.active);
    await tester.pumpAndSettle();
    expect(selectedTab(tester), 0);
  });
}
