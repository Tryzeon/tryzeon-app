import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/store/product/presentation/sheets/product_style_sheet.dart';

import '../../../../../support/sheet_test_host.dart';

void main() {
  final first = ClothingStyle.values.first;
  final picked = ClothingStyle.values[5];

  Future<List<Set<ClothingStyle>>> open(
    final WidgetTester tester, {
    final Set<ClothingStyle> initialSelection = const {},
  }) async {
    final changes = <Set<ClothingStyle>>[];
    await openSheet<void>(
      tester,
      (final context) => ProductStyleSheet.show(
        context: context,
        initialSelection: initialSelection,
        onChanged: changes.add,
      ),
    );
    return changes;
  }

  testWidgets('reports each toggle live and stays open', (final tester) async {
    final changes = await open(tester);

    await tester.tap(find.text(first.label));
    await tester.pumpAndSettle();

    expect(changes, [
      {first},
    ]);
    expect(find.byType(ProductStyleSheet), findsOneWidget);
  });

  testWidgets('keeps toggles made before a drag dismiss', (final tester) async {
    final changes = await open(tester);

    await tester.tap(find.text(first.label));
    await tester.pumpAndSettle();
    await dismissByDrag(tester);

    expect(find.byType(ProductStyleSheet), findsNothing);
    expect(changes.last, {first});
  });

  testWidgets('lists the styles selected at open first', (final tester) async {
    await open(tester, initialSelection: {picked});

    final firstTile = tester.widget<CheckboxListTile>(
      find.byType(CheckboxListTile).first,
    );
    expect((firstTile.title! as Text).data, picked.label);
  });

  testWidgets('shows the selected count in the title', (final tester) async {
    await open(tester, initialSelection: {picked});

    expect(find.text('選擇風格（1）'), findsOneWidget);

    await tester.tap(find.text(first.label));
    await tester.pumpAndSettle();

    expect(find.text('選擇風格（2）'), findsOneWidget);
  });
}
