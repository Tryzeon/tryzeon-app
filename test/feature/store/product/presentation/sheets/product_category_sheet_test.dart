import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/garment_type/presentation/garment_type_display.dart';
import 'package:tryzeon/feature/common/product_category/domain/entities/product_category.dart';
import 'package:tryzeon/feature/store/product/presentation/sheets/product_category_sheet.dart';

import '../../../../../support/sheet_test_host.dart';

void main() {
  const tee = ProductCategory(
    id: 'tee',
    code: 'tee',
    name: 'T恤',
    defaultGarmentType: GarmentType.top,
  );
  const shirt = ProductCategory(
    id: 'shirt',
    code: 'shirt',
    name: '襯衫',
    defaultGarmentType: GarmentType.top,
  );
  const jeans = ProductCategory(
    id: 'jeans',
    code: 'jeans',
    name: '牛仔褲',
    defaultGarmentType: GarmentType.pants,
  );
  const categories = [tee, shirt, jeans];

  testWidgets('opens on the group holding the current category', (
    final tester,
  ) async {
    await openSheet<ProductCategory>(
      tester,
      (final context) => ProductCategorySheet.show(
        context: context,
        categories: categories,
        initialId: jeans.id,
      ),
    );

    expect(find.text(jeans.name), findsOneWidget);
    expect(find.text(tee.name), findsNothing);
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, jeans.name),
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsOneWidget,
    );
  });

  testWidgets('switches group and returns the tapped category', (
    final tester,
  ) async {
    final sheet = await openSheet<ProductCategory>(
      tester,
      (final context) => ProductCategorySheet.show(
        context: context,
        categories: categories,
        initialId: jeans.id,
      ),
    );

    await tester.tap(find.text(GarmentType.top.displayName));
    await tester.pumpAndSettle();
    await tester.tap(find.text(shirt.name));
    await tester.pumpAndSettle();

    expect(find.byType(ProductCategorySheet), findsNothing);
    expect(await sheet.result, shirt);
  });
}
