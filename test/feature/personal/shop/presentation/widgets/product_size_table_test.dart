import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/product_size.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/fit_result.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/product_size_table.dart';

void main() {
  testWidgets('shows garment and body range values with their unit', (
    final tester,
  ) async {
    final size = ProductSize(
      id: 's1',
      productId: 'p1',
      name: 'M',
      garmentMeasurements: const GarmentMeasurements(chestCircumference: 100),
      bodyMeasurementRanges: const BodyMeasurementRanges(
        weight: MeasurementRange(min: 50, max: 60),
      ),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductSizeTable(
            sizes: [size],
            columnTypes: const [GarmentMeasurementType.chestCircumference],
            fitResult: const FitResult(),
          ),
        ),
      ),
    );

    expect(find.text('商品尺寸'), findsOneWidget);
    expect(find.text('100 cm'), findsOneWidget);
    expect(find.text('50–60 kg'), findsOneWidget);
  });
}
