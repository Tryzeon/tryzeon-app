import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/data/services/image_analysis_api.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/services/label_tagger_impl.dart';
import 'package:typed_result/typed_result.dart';

void main() {
  group('parseAnalysisResponse', () {
    test('drops empty tags and parses a known garment type', () {
      final result = parseAnalysisResponse({
        'tags': ['a', ''],
        'garment_type': 'skirt',
      });

      expect(result.tags, ['a']);
      expect(result.garmentType, GarmentType.skirt);
    });

    test('returns null garment type for an unknown value', () {
      final result = parseAnalysisResponse({'garment_type': 'bottoms'});

      expect(result.garmentType, isNull);
    });

    test('returns empty tags and null garment type for an empty response', () {
      final result = parseAnalysisResponse({});

      expect(result.tags, isEmpty);
      expect(result.garmentType, isNull);
    });
  });

  test('a failed analysis is reported as a failure', () async {
    final result = await LabelTaggerImpl(_FailingApi()).analyze(File('a.jpg'));

    expect(result.getError(), const NetworkFailure());
  });
}

class _FailingApi implements ImageAnalysisApi {
  @override
  Future<Map<String, dynamic>?> analyze({
    required final File image,
    required final String functionName,
  }) async => throw const SocketException('offline');

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
