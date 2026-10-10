import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/product_advanced_fields_editor.dart';

void main() {
  late ValueNotifier<String?> material;
  late ValueNotifier<ProductFit?> fit;
  late ValueNotifier<ProductElasticity?> elasticity;
  late ValueNotifier<ProductThickness?> thickness;
  late ValueNotifier<Set<ClothingStyle>?> styles;
  late ValueNotifier<Set<ProductSeason>?> seasons;

  setUp(() {
    material = ValueNotifier(null);
    fit = ValueNotifier(null);
    elasticity = ValueNotifier(null);
    thickness = ValueNotifier(null);
    styles = ValueNotifier(null);
    seasons = ValueNotifier(null);
  });

  Future<void> pumpEditor(final WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: ProductAdvancedFieldsEditor(
          selectedMaterial: material,
          selectedFit: fit,
          selectedElasticity: elasticity,
          selectedThickness: thickness,
          selectedStyles: styles,
          selectedSeasons: seasons,
        ),
      ),
    ),
  );

  testWidgets('lists the optional fields while none is filled', (
    final tester,
  ) async {
    await pumpEditor(tester);

    expect(find.text('選填：風格、季節、材質、彈性、版型、厚度'), findsOneWidget);
  });

  testWidgets('counts filled fields as they change', (final tester) async {
    await pumpEditor(tester);

    styles.value = {ClothingStyle.korean};
    material.value = '棉 100%';
    fit.value = ProductFit.regular;
    await tester.pump();
    expect(find.text('已填 3 / 6 項'), findsOneWidget);

    material.value = '';
    styles.value = {};
    await tester.pump();
    expect(find.text('已填 1 / 6 項'), findsOneWidget);
  });
}
