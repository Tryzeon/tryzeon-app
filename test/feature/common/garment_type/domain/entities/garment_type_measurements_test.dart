import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type_measurements.dart';

void main() {
  group('GarmentType.measurementTypes', () {
    test('top, outerwear and dress share the upper-body set', () {
      const expected = [
        GarmentMeasurementType.sleeveLength,
        GarmentMeasurementType.shoulderWidth,
        GarmentMeasurementType.chestCircumference,
        GarmentMeasurementType.length,
      ];
      expect(GarmentType.top.measurementTypes, expected);
      expect(GarmentType.outerwear.measurementTypes, expected);
      expect(GarmentType.dress.measurementTypes, expected);
    });

    test('skirt has waist, hip and length', () {
      expect(GarmentType.skirt.measurementTypes, const [
        GarmentMeasurementType.waistCircumference,
        GarmentMeasurementType.hipCircumference,
        GarmentMeasurementType.length,
      ]);
    });

    test('pants add thigh and leg opening to the skirt set', () {
      expect(GarmentType.pants.measurementTypes, const [
        GarmentMeasurementType.waistCircumference,
        GarmentMeasurementType.hipCircumference,
        GarmentMeasurementType.thighCircumference,
        GarmentMeasurementType.length,
        GarmentMeasurementType.legOpening,
      ]);
    });

    test('others opens every dimension', () {
      expect(GarmentType.others.measurementTypes, GarmentMeasurementType.values);
    });
  });

  group('GarmentType.tryFromString', () {
    test('round-trips every value', () {
      for (final type in GarmentType.values) {
        expect(GarmentType.tryFromString(type.value), type);
      }
    });

    test('returns null for unknown and null input', () {
      expect(GarmentType.tryFromString('bottoms'), isNull);
      expect(GarmentType.tryFromString(null), isNull);
    });
  });
}
