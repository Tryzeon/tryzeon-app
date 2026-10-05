import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/product_attributes/presentation/product_attributes_extensions.dart';
import 'package:tryzeon/feature/store/product/presentation/sheets/product_material_sheet.dart';

import '../../../../../support/sheet_test_host.dart';

void main() {
  final preset = kMaterialPresets.first;
  const custom = '再生纖維';

  Future<({Future<ProductMaterialResult?> result})> open(
    final WidgetTester tester, {
    final String? initialValue,
  }) => openSheet<ProductMaterialResult>(
    tester,
    (final context) =>
        ProductMaterialSheet.show(context: context, initialValue: initialValue),
  );

  testWidgets('returns a preset as soon as it is tapped', (final tester) async {
    final sheet = await open(tester);

    await tester.tap(find.text(preset));
    await tester.pumpAndSettle();

    expect(find.byType(ProductMaterialSheet), findsNothing);
    expect(await sheet.result, (value: preset));
  });

  testWidgets('returns custom text from the confirm button', (
    final tester,
  ) async {
    final sheet = await open(tester);

    await tester.enterText(find.byType(TextField), custom);
    await tester.pump();
    await tester.tap(find.byTooltip('使用自訂材質'));
    await tester.pumpAndSettle();

    expect(find.byType(ProductMaterialSheet), findsNothing);
    expect(await sheet.result, (value: custom));
  });

  testWidgets('returns custom text from the keyboard done action', (
    final tester,
  ) async {
    final sheet = await open(tester);

    await tester.enterText(find.byType(TextField), custom);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byType(ProductMaterialSheet), findsNothing);
    expect(await sheet.result, (value: custom));
  });

  testWidgets('keeps the sheet open when submitting blank custom text', (
    final tester,
  ) async {
    await open(tester);

    await tester.enterText(find.byType(TextField), '  ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byType(ProductMaterialSheet), findsOneWidget);
  });

  testWidgets('offers clearing only when a material is set', (
    final tester,
  ) async {
    await open(tester);

    expect(find.text('清除'), findsNothing);
  });

  testWidgets('clearing returns an explicit null', (final tester) async {
    final sheet = await open(tester, initialValue: preset);

    await tester.tap(find.text('清除'));
    await tester.pumpAndSettle();

    expect(find.byType(ProductMaterialSheet), findsNothing);
    expect(await sheet.result, (value: null));
  });

  testWidgets('prefills a custom initial value into the field', (
    final tester,
  ) async {
    await open(tester, initialValue: custom);

    expect(find.widgetWithText(TextField, custom), findsOneWidget);
  });
}
