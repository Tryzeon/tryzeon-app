import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/body_measurement_ranges.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/garment_measurement_type.dart';
import 'package:tryzeon/feature/store/product/data/services/size_voice_parser.dart';

void main() {
  group('parseSizeVoiceResponse', () {
    test('reads a body measurement range for every body measurement type', () {
      final parsed = parseSizeVoiceResponse({
        'sizes': [
          {
            'name': 'M',
            'garment_measurements': <String, dynamic>{},
            'body_measurement_ranges': {
              for (final type in BodyMeasurementType.values)
                type.value: {'min': type.min, 'max': type.max},
            },
          },
        ],
      });

      final ranges = parsed.single.bodyMeasurementRanges;
      for (final type in BodyMeasurementType.values) {
        expect(ranges[type], MeasurementRange(min: type.min, max: type.max));
      }
    });

    test('reads measurements and body measurement ranges for each size', () {
      final parsed = parseSizeVoiceResponse({
        'sizes': [
          {
            'name': 'M',
            'garment_measurements': {
              'chest_circumference': {'value': 100, 'unit': 'centimeter'},
            },
            'body_measurement_ranges': {
              'height': {'min': 160, 'max': 170},
              'weight': {'min': 50, 'max': 60.5},
            },
          },
        ],
      });

      final size = parsed.single;
      expect(
        size.garmentMeasurements[GarmentMeasurementType.chestCircumference]?.value,
        100,
      );
      expect(
        size.bodyMeasurementRanges[BodyMeasurementType.height],
        const MeasurementRange(min: 160, max: 170),
      );
      expect(
        size.bodyMeasurementRanges[BodyMeasurementType.weight],
        const MeasurementRange(min: 50, max: 60.5),
      );
    });

    test('ignores an unknown or half-formed body measurement range', () {
      final parsed = parseSizeVoiceResponse({
        'sizes': [
          {
            'name': 'M',
            'garment_measurements': <String, dynamic>{},
            'body_measurement_ranges': {
              'neck': {'min': 36, 'max': 40},
              'height': {'min': 160},
            },
          },
        ],
      });

      expect(parsed.single.bodyMeasurementRanges, isEmpty);
    });

    test('yields an empty body measurement range when the key is absent', () {
      final parsed = parseSizeVoiceResponse({
        'sizes': [
          {'name': 'M', 'garment_measurements': <String, dynamic>{}},
        ],
      });

      expect(parsed.single.bodyMeasurementRanges, isEmpty);
    });
  });
}
