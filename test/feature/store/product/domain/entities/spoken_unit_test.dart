import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/measurement/domain/entities/measurement_unit.dart';
import 'package:tryzeon/feature/store/product/domain/entities/spoken_unit.dart';

void main() {
  group('resolve', () {
    test('a unit the store named is kept whatever the form is in', () {
      expect(
        SpokenUnit.inch.resolve(formUnit: MeasurementUnit.centimeter),
        MeasurementUnit.inch,
      );
      expect(
        SpokenUnit.cun.resolve(formUnit: MeasurementUnit.inch),
        MeasurementUnit.cun,
      );
    });

    test('no unit spoken means the unit the form is in', () {
      for (final unit in MeasurementUnit.values) {
        expect(SpokenUnit.unspecified.resolve(formUnit: unit), unit);
      }
    });

    test('a bare 寸 is the form unit when that is 台寸 or 英吋', () {
      expect(
        SpokenUnit.cunAmbiguous.resolve(formUnit: MeasurementUnit.cun),
        MeasurementUnit.cun,
      );
      expect(
        SpokenUnit.cunAmbiguous.resolve(formUnit: MeasurementUnit.inch),
        MeasurementUnit.inch,
      );
    });

    test('a bare 寸 is 英吋 when the form is in centimeters', () {
      expect(
        SpokenUnit.cunAmbiguous.resolve(formUnit: MeasurementUnit.centimeter),
        MeasurementUnit.inch,
      );
    });
  });
}
