import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/garment_type/presentation/measurement_guide_sheet.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/product_size.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/fit_result.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/product_size_table.dart';

ProductSize _size({
  final GarmentMeasurements? garmentMeasurements,
  final BodyMeasurementRanges? bodyMeasurementRanges,
}) => ProductSize(
  id: 's1',
  productId: 'p1',
  name: 'M',
  garmentMeasurements: garmentMeasurements,
  bodyMeasurementRanges: bodyMeasurementRanges,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

Widget _table({
  required final ProductSize size,
  required final List<GarmentMeasurementType> columnTypes,
  required final GarmentType garmentType,
}) => MaterialApp(
  home: Scaffold(
    body: ProductSizeTable(
      sizes: [size],
      columnTypes: columnTypes,
      garmentType: garmentType,
      fitResult: const FitResult(),
    ),
  ),
);

void main() {
  testWidgets('shows garment and body range values with their unit', (
    final tester,
  ) async {
    await tester.pumpWidget(
      _table(
        size: _size(
          garmentMeasurements: const GarmentMeasurements(chestCircumference: 100),
          bodyMeasurementRanges: const BodyMeasurementRanges(
            weight: MeasurementRange(min: 50, max: 60),
          ),
        ),
        columnTypes: const [GarmentMeasurementType.chestCircumference],
        garmentType: GarmentType.top,
      ),
    );

    expect(find.text('商品尺寸'), findsOneWidget);
    expect(find.text('100 cm'), findsOneWidget);
    expect(find.text('50–60 kg'), findsOneWidget);
  });

  testWidgets('labels the length column by the garment type', (final tester) async {
    await tester.pumpWidget(
      _table(
        size: _size(garmentMeasurements: const GarmentMeasurements(length: 98)),
        columnTypes: const [GarmentMeasurementType.length],
        garmentType: GarmentType.pants,
      ),
    );

    expect(find.text('褲長'), findsOneWidget);
    expect(find.text('長度'), findsNothing);
  });

  testWidgets('offers the measurement guide only for garment types that have one', (
    final tester,
  ) async {
    final size = _size(garmentMeasurements: const GarmentMeasurements(length: 60));

    await tester.pumpWidget(
      _table(
        size: size,
        columnTypes: const [GarmentMeasurementType.length],
        garmentType: GarmentType.others,
      ),
    );
    expect(find.text('測量方式'), findsNothing);

    await tester.pumpWidget(
      _table(
        size: size,
        columnTypes: const [GarmentMeasurementType.length],
        garmentType: GarmentType.top,
      ),
    );
    await tester.tap(find.text('測量方式'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(MeasurementGuideSheet), findsOneWidget);
    expect(find.text('上衣測量方式'), findsOneWidget);
  });
}
