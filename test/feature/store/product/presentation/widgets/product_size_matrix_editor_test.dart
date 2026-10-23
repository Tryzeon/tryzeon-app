import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/garment_type/presentation/sheets/measurement_guide_sheet.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/garment_measurement_type.dart';
import 'package:tryzeon/feature/store/product/presentation/hooks/use_product_size_manager.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/product_size_matrix_editor.dart';

Widget _editor({final GarmentType? garmentType}) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: HookBuilder(
        builder: (final context) => ProductSizeMatrixEditor(
          manager: useProductSizeManager(),
          visibleTypes: const [GarmentMeasurementType.length],
          garmentType: garmentType,
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'offers every measurement guide before a garment type is chosen',
    (final tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_editor());

      await tester.tap(find.text('M'));
      await tester.pump();
      await tester.tap(find.text('測量方式'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(MeasurementGuideSheet), findsOneWidget);
      expect(find.text('測量方式'), findsNWidgets(2));
      expect(find.byType(SmoothPageIndicator), findsOneWidget);
    },
  );

  testWidgets('shows only the chosen garment type\'s guide', (
    final tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_editor(garmentType: GarmentType.skirt));

    await tester.tap(find.text('M'));
    await tester.pump();
    await tester.tap(find.text('測量方式'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(MeasurementGuideSheet), findsOneWidget);
    expect(find.byType(SmoothPageIndicator), findsNothing);
  });
}
