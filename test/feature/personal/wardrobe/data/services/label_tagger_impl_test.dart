import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/services/label_tagger_impl.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/label_result.dart';
import 'package:typed_result/typed_result.dart';

import '../../../../../support/fake_functions_client.dart';

Future<Result<LabelResult, Failure>> _analyze(
  final FakeFunctionsClient functions, {
  final String? encoded = 'aGVsbG8=',
}) => LabelTaggerImpl(
  FakeSupabaseClient(functions),
  encodeImage: (_) async => encoded,
).analyze(File('a.jpg'));

void main() {
  test('sends the encoded image to the wardrobe analysis function', () async {
    final functions = FakeFunctionsClient(data: {'tags': <String>[]});

    await _analyze(functions);

    expect(functions.invokedFunction, 'analyze-wardrobe-image');
    expect(functions.sentBody, {'base64': 'aGVsbG8='});
  });

  test('maps the tags and garment type', () async {
    final result = await _analyze(
      FakeFunctionsClient(
        data: {
          'tags': ['denim'],
          'garment_type': 'skirt',
        },
      ),
    );

    expect(
      result.get(),
      const LabelResult(tags: ['denim'], garmentType: GarmentType.skirt),
    );
  });

  test('a garment type this client does not know decodes to null', () async {
    final result = await _analyze(
      FakeFunctionsClient(
        data: {'tags': <String>[], 'garment_type': 'bottoms'},
      ),
    );

    expect(result.get()?.garmentType, isNull);
  });

  test('an image that cannot be compressed yields an empty result', () async {
    final functions = FakeFunctionsClient();

    final result = await _analyze(functions, encoded: null);

    expect(result.get(), const LabelResult());
    expect(functions.invokedFunction, isNull);
  });

  test('a body that breaks the contract is a server failure', () async {
    final result = await _analyze(FakeFunctionsClient(data: 'not an object'));

    expect(result.getError(), const ServerFailure());
  });

  test('a failed analysis is reported as a failure', () async {
    final result = await _analyze(
      FakeFunctionsClient(error: const SocketException('offline')),
    );

    expect(result.getError(), const NetworkFailure());
  });
}
