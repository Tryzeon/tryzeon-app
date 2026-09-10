import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/measurement/domain/entities/measurement_unit.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/body_measurement_ranges.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/garment_category_measurements.dart';
import 'package:tryzeon/feature/store/product/domain/entities/parsed_size.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/size_item.dart';
import 'package:tryzeon/feature/store/product/presentation/controllers/product_size_entry_controller.dart';

void main() {
  group('matchKey', () {
    test('does not fold aliases: XXL and 2XL are different sizes', () {
      expect(
        ProductSizeEntryController(label: 'XXL').matchKey,
        isNot(ProductSizeEntryController(label: '2XL').matchKey),
      );
    });

    test('case differences are the same size', () {
      expect(
        ProductSizeEntryController(label: 'm').matchKey,
        ProductSizeEntryController(label: 'M').matchKey,
      );
    });

    test('a custom size is only normalized for case', () {
      expect(ProductSizeEntryController(label: 'us 10').matchKey, 'US 10');
    });
  });

  group('toSizeItem', () {
    test('with no id it produces a NewSizeItem named after the label', () {
      final entry = ProductSizeEntryController(label: '4XL');
      entry.measurementControllers[GarmentMeasurementType.chestCircumference]!.text =
          '100';
      final item = entry.toSizeItem(
        unit: MeasurementUnit.centimeter,
        visibleTypes: const [GarmentMeasurementType.chestCircumference],
      );
      expect(item, isA<NewSizeItem>());
      expect((item as NewSizeItem).name, '4XL');
      expect(
        item.garmentMeasurements?.getValue(GarmentMeasurementType.chestCircumference),
        100,
      );
    });

    test('with an id it produces an ExistingSizeItem', () {
      final entry = ProductSizeEntryController(label: 'M', id: 'size-1');
      final item = entry.toSizeItem(
        unit: MeasurementUnit.centimeter,
        visibleTypes: const [GarmentMeasurementType.chestCircumference],
      );
      expect(item, isA<ExistingSizeItem>());
      expect((item as ExistingSizeItem).id, 'size-1');
    });
  });

  group('bodyMeasurementRanges', () {
    test('has a min/max controller pair for every body measurement range type', () {
      final entry = ProductSizeEntryController(label: 'M');
      expect(entry.rangeControllers.keys, bodyMeasurementRangeTypes);
    });

    test('is omitted when no range is filled', () {
      final entry = ProductSizeEntryController(label: 'M');
      final item = entry.toSizeItem(
        unit: MeasurementUnit.centimeter,
        visibleTypes: const [],
      );
      expect((item as NewSizeItem).bodyMeasurementRanges, isNull);
    });

    test('builds a range from both bounds and skips a half-filled pair', () {
      final entry = ProductSizeEntryController(label: 'M');
      entry.rangeControllers[BodyMeasurementType.height]!.min.text = '160';
      entry.rangeControllers[BodyMeasurementType.height]!.max.text = '170';
      entry.rangeControllers[BodyMeasurementType.weight]!.min.text = '50';

      final item = entry.toSizeItem(
        unit: MeasurementUnit.centimeter,
        visibleTypes: const [],
      );

      final range = (item as NewSizeItem).bodyMeasurementRanges;
      expect(range?.height, const MeasurementRange(min: 160, max: 170));
      expect(range?.weight, isNull);
    });

    test('pre-fills from an existing size without trailing zeros', () {
      final entry = ProductSizeEntryController(
        label: 'M',
        bodyMeasurementRanges: const BodyMeasurementRanges(
          height: MeasurementRange(min: 160, max: 170.5),
        ),
      );
      expect(entry.rangeControllers[BodyMeasurementType.height]!.min.text, '160');
      expect(entry.rangeControllers[BodyMeasurementType.height]!.max.text, '170.5');
    });

    test('is not rescaled when the garment unit changes', () {
      final entry = ProductSizeEntryController(label: 'M');
      entry.measurementControllers[GarmentMeasurementType.chestCircumference]!.text =
          '100';
      entry.rangeControllers[BodyMeasurementType.height]!.min.text = '160';
      entry.rangeControllers[BodyMeasurementType.height]!.max.text = '170';

      entry.convertValues(
        fromUnit: MeasurementUnit.centimeter,
        toUnit: MeasurementUnit.inch,
      );

      expect(
        entry.measurementControllers[GarmentMeasurementType.chestCircumference]!.text,
        isNot('100'),
      );
      expect(entry.rangeControllers[BodyMeasurementType.height]!.min.text, '160');
      expect(entry.rangeControllers[BodyMeasurementType.height]!.max.text, '170');
    });

    test('applies a parsed body measurement range', () {
      final entry = ProductSizeEntryController(label: 'M');
      entry.applyParsed(
        const ParsedSize(
          name: 'M',
          bodyMeasurementRanges: {
            BodyMeasurementType.weight: MeasurementRange(min: 50, max: 60),
          },
        ),
        targetUnit: MeasurementUnit.centimeter,
      );
      expect(entry.rangeControllers[BodyMeasurementType.weight]!.min.text, '50');
      expect(entry.rangeControllers[BodyMeasurementType.weight]!.max.text, '60');
    });
  });
}
