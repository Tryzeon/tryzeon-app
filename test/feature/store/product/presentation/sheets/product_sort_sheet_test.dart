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
      const SortCondition(key: price, ascending: true),
    );
    expect(find.byType(ProductSortSheet), findsOneWidget);
  });

  testWidgets('a newly picked field starts from its own default direction', (
    final tester,
  ) async {
    await open(tester);

    for (final key in allSortKeys) {
      await tester.tap(find.text(key.label));
      await tester.pumpAndSettle();

      expect(
        containerOf(tester).read(productQueryProvider).sort,
        SortCondition.byDefault(key),
        reason: key.label,
      );
    }
  });

  testWidgets('re-picking the current field keeps the flipped direction', (
    final tester,
  ) async {
    await open(tester);

    await tester.tap(find.text(price.label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(price.descendingLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(price.label));
    await tester.pumpAndSettle();

    expect(
      containerOf(tester).read(productQueryProvider).sort,
      const SortCondition(key: price, ascending: false),
    );
  });

  testWidgets('puts each field\'s default direction on the left', (
    final tester,
  ) async {
    await open(tester);

    for (final key in allSortKeys) {
      await tester.tap(find.text(key.label));
      await tester.pumpAndSettle();

      final defaultLabel = key.directionLabel(ascending: key.defaultAscending);
      final otherLabel = key.directionLabel(ascending: !key.defaultAscending);
      expect(
        tester.getCenter(find.text(defaultLabel)).dx,
        lessThan(tester.getCenter(find.text(otherLabel)).dx),
        reason: key.label,
      );
    }
  });

  testWidgets('flips direction with labels for the picked field', (
    final tester,
  ) async {
    await open(tester);

    await tester.tap(find.text(price.label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(price.descendingLabel));
    await tester.pumpAndSettle();

    expect(
      containerOf(tester).read(productQueryProvider).sort,
      const SortCondition(key: price, ascending: false),
    );
  });
}
