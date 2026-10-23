import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/body_measurement_ranges.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/garment_measurement_type.dart';
import 'package:tryzeon/feature/store/product/data/services/size_voice_parser_impl.dart';
import 'package:tryzeon/feature/store/product/domain/entities/parsed_size.dart';
import 'package:tryzeon/feature/store/product/domain/entities/spoken_unit.dart';
import 'package:typed_result/typed_result.dart';

import '../../../../../support/fake_functions_client.dart';

Future<Result<List<ParsedSize>, Failure>> _parse(
  final FakeFunctionsClient functions,
) => SizeVoiceParserImpl(
  FakeSupabaseClient(functions),
).parse(audioBytes: Uint8List.fromList([1, 2, 3]), mimeType: 'audio/m4a');

Map<String, dynamic> _size({
  final Map<String, dynamic> garmentMeasurements = const {},
  final Map<String, dynamic> bodyMeasurementRanges = const {},
}) => {
  'name': 'M',
  'garment_measurements': garmentMeasurements,
  'body_measurement_ranges': bodyMeasurementRanges,
};

void main() {
  test('sends only the audio and its mime type', () async {
    final functions = FakeFunctionsClient(data: {'sizes': <Object>[]});

    await _parse(functions);

    expect(functions.sentBody, {
      'audioBase64': 'AQID',
      'mimeType': 'audio/m4a',
    });
  });

  test('reads a unit the model could not settle as spoken', () async {
    final result = await _parse(
      FakeFunctionsClient(
        data: {
          'sizes': [
            _size(
              garmentMeasurements: {
                'chest_circumference': {'value': 50, 'unit': 'unspecified'},
                'waist_circumference': {'value': 28, 'unit': 'cun_ambiguous'},
              },
            ),
          ],
        },
      ),
    );

    final measurements = result.get()!.single.garmentMeasurements;
    expect(
      measurements[GarmentMeasurementType.chestCircumference]!.unit,
      SpokenUnit.unspecified,
    );
    expect(
      measurements[GarmentMeasurementType.waistCircumference]!.unit,
      SpokenUnit.cunAmbiguous,
    );
  });

  test(
    'reads measurements and body measurement ranges for each size',
    () async {
      final result = await _parse(
        FakeFunctionsClient(
          data: {
            'sizes': [
              _size(
                garmentMeasurements: {
                  'chest_circumference': {'value': 100, 'unit': 'inch'},
                },
                bodyMeasurementRanges: {
                  'height': {'min': 160, 'max': 170},
                  'weight': {'min': 50, 'max': 60.5},
                },
              ),
            ],
          },
        ),
      );

      final size = result.get()!.single;
      final chest =
          size.garmentMeasurements[GarmentMeasurementType.chestCircumference]!;
      expect(chest.value, 100);
      expect(chest.unit, SpokenUnit.inch);
      expect(size.bodyMeasurementRanges, {
        BodyMeasurementType.height: const MeasurementRange(min: 160, max: 170),
        BodyMeasurementType.weight: const MeasurementRange(min: 50, max: 60.5),
      });
    },
  );

  test(
    'reads a body measurement range for every body measurement type',
    () async {
      final result = await _parse(
        FakeFunctionsClient(
          data: {
            'sizes': [
              _size(
                bodyMeasurementRanges: {
                  for (final type in BodyMeasurementType.values)
                    type.value: {'min': type.min, 'max': type.max},
                },
              ),
            ],
          },
        ),
      );

      final ranges = result.get()!.single.bodyMeasurementRanges;
      for (final type in BodyMeasurementType.values) {
        expect(ranges[type], MeasurementRange(min: type.min, max: type.max));
      }
    },
  );

  test('drops measurement keys this client does not know yet', () async {
    final result = await _parse(
      FakeFunctionsClient(
        data: {
          'sizes': [
            _size(
              garmentMeasurements: {
                'cuff_width': {'value': 10, 'unit': 'centimeter'},
              },
              bodyMeasurementRanges: {
                'neck': {'min': 36, 'max': 40},
              },
            ),
          ],
        },
      ),
    );

    final size = result.get()!.single;
    expect(size.garmentMeasurements, isEmpty);
    expect(size.bodyMeasurementRanges, isEmpty);
  });

  test('a body that breaks the contract is a server failure', () async {
    final result = await _parse(
      FakeFunctionsClient(
        data: {
          'sizes': [
            _size(
              bodyMeasurementRanges: {
                'height': {'min': 160},
              },
            ),
          ],
        },
      ),
    );

    expect(result.getError(), const ServerFailure());
  });
}
