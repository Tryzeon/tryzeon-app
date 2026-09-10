import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/body_measurement_ranges.dart';

void main() {
  group('MeasurementRange', () {
    const range = MeasurementRange(min: 160, max: 170);

    test('contains its bounds inclusively', () {
      expect(range.contains(160), isTrue);
      expect(range.contains(170), isTrue);
      expect(range.contains(159.9), isFalse);
      expect(range.contains(170.1), isFalse);
    });

    test('distanceOutside is zero inside and the gap to the nearer bound outside', () {
      expect(range.distanceOutside(165), 0);
      expect(range.distanceOutside(157), 3);
      expect(range.distanceOutside(174), 4);
    });

    test('center is the midpoint', () {
      expect(range.center, 165);
    });
  });

  group('BodyMeasurementRanges', () {
    test('round-trips through fromValues and getValue by body type', () {
      final range = BodyMeasurementRanges.fromValues({
        BodyMeasurementType.height: const MeasurementRange(min: 160, max: 170),
        BodyMeasurementType.weight: const MeasurementRange(min: 50, max: 60),
      });

      expect(
        range[BodyMeasurementType.height],
        const MeasurementRange(min: 160, max: 170),
      );
      expect(range[BodyMeasurementType.weight], const MeasurementRange(min: 50, max: 60));
      expect(range[BodyMeasurementType.chest], isNull);
      expect(range.isEmpty, isFalse);
    });

    test('is empty when no type has a range', () {
      expect(const BodyMeasurementRanges().isEmpty, isTrue);
    });
  });
}
