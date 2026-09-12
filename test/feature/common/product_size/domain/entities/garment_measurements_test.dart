import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/garment_measurements.dart';

void main() {
  test('fromValues and getValue round-trip every dimension', () {
    final values = {
      for (final (i, type) in GarmentMeasurementType.values.indexed) type: 10.0 + i,
    };
    final measurements = GarmentMeasurements.fromValues(values);
    for (final type in GarmentMeasurementType.values) {
      expect(measurements.getValue(type), values[type]);
      expect(measurements[type], values[type]);
    }
  });
}
