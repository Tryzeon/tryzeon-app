import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/garment_type/presentation/garment_type_display.dart';
import 'package:tryzeon/feature/personal/wardrobe/presentation/sheets/wardrobe_garment_type_sheet.dart';

import '../../../../../support/sheet_test_host.dart';

void main() {
  testWidgets('marks the current type and returns the tapped one', (
    final tester,
  ) async {
    final sheet = await openSheet<GarmentType>(
      tester,
      (final context) => WardrobeGarmentTypeSheet.show(
        context: context,
        selected: GarmentType.pants,
      ),
    );

    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, GarmentType.pants.displayName),
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text(GarmentType.skirt.displayName));
    await tester.pumpAndSettle();

    expect(find.byType(WardrobeGarmentTypeSheet), findsNothing);
    expect(await sheet.result, GarmentType.skirt);
  });

  testWidgets('fits every type on a short screen without overflowing', (
    final tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 480);
    addTearDown(tester.view.reset);

    await openSheet<GarmentType>(
      tester,
      (final context) => WardrobeGarmentTypeSheet.show(
        context: context,
        selected: GarmentType.top,
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
