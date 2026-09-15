import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type_measurements.dart';
import 'package:tryzeon/feature/common/garment_type/presentation/garment_type_display.dart';

void main() {
  group('GarmentTypeDisplay.lengthLabel', () {
    test('names the length by what the garment covers', () {
      expect(GarmentType.top.lengthLabel, '衣長');
      expect(GarmentType.outerwear.lengthLabel, '衣長');
      expect(GarmentType.dress.lengthLabel, '總長');
      expect(GarmentType.skirt.lengthLabel, '裙長');
      expect(GarmentType.pants.lengthLabel, '褲長');
      expect(GarmentType.others.lengthLabel, '長度');
    });
  });

  group('GarmentTypeDisplay.measurementLabel', () {
    test('uses the type-specific label for length', () {
      expect(GarmentType.pants.measurementLabel(GarmentMeasurementType.length), '褲長');
    });

    test('keeps the generic label for every other measurement', () {
      expect(
        GarmentType.pants.measurementLabel(GarmentMeasurementType.waistCircumference),
        '腰圍',
      );
    });
  });
}
