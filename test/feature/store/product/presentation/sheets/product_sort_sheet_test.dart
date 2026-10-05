import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/store/product/presentation/mappers/product_sort_field_ui_mapper.dart';
import 'package:tryzeon/feature/store/product/presentation/sheets/product_sort_sheet.dart';
import 'package:tryzeon/feature/store/product/presentation/state/product_sort_condition.dart';
import 'package:tryzeon/feature/store/product/providers/store_product_providers.dart';

import '../../../../../support/sheet_test_host.dart';

void main() {
  const price = SortKey.product(ProductField.price);

  ProviderContainer containerOf(final WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(ProductSortSheet)));

  Future<void> open(final WidgetTester tester) =>
      openSheet<void>(tester, ProductSortSheet.show);

  testWidgets('lists the sort fields above the direction toggle', (
    final tester,
  ) async {
    await open(tester);

    expect(
      tester.getCenter(find.text(allSortKeys.last.label)).dy,
      lessThan(tester.getCenter(find.byType(SegmentedButton<bool>)).dy),
    );
  });

  testWidgets('applies a picked field live and stays open', (
    final tester,
  ) async {
    await open(tester);

    await tester.tap(find.text(price.label));
    await tester.pumpAndSettle();

    expect(
      containerOf(tester).read(productQueryProvider).sort,
      SortCondition(key: price, ascending: SortCondition.defaultSort.ascending),
    );
    expect(find.byType(ProductSortSheet), findsOneWidget);
  });

  testWidgets('flips direction with labels for the picked field', (
    final tester,
  ) async {
    await open(tester);

    await tester.tap(find.text(price.label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(price.ascendingLabel));
    await tester.pumpAndSettle();

    expect(
      containerOf(tester).read(productQueryProvider).sort,
      const SortCondition(key: price, ascending: true),
    );
  });
}
