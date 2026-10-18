import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/store/product/data/services/product_image_analyzer_impl.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product_analysis_result.dart';
import 'package:typed_result/typed_result.dart';

import '../../../../../support/fake_functions_client.dart';

Future<Result<ProductAnalysisResult, Failure>> _analyze(
  final FakeFunctionsClient functions,
) => ProductImageAnalyzerImpl(
  FakeSupabaseClient(functions),
  encodeImage: (_) async => 'aGVsbG8=',
).analyze(File('a.jpg'));

void main() {
  test('parses the analysis into a result', () async {
    final functions = FakeFunctionsClient(
      data: {
        'name': '碎花洋裝',
        'categoryId': 'c1',
        'gender': 'female',
        'styles': ['korean', 'y2k'],
        'seasons': <String>[],
        'material': null,
        'fit': 'oversized',
        'thickness': null,
        'elasticity': null,
      },
    );

    final analysis = (await _analyze(functions)).get()!;

    expect(functions.invokedFunction, 'analyze-product-image');
    expect(analysis.name, '碎花洋裝');
    expect(analysis.categoryId, 'c1');
    expect(analysis.gender, ProductGender.female);
    expect(analysis.styles, {ClothingStyle.korean});
    expect(analysis.fit, isNull);
  });

  test('a failed analysis is reported as a failure', () async {
    final result = await _analyze(
      FakeFunctionsClient(error: const SocketException('offline')),
    );

    expect(result.getError(), const NetworkFailure());
  });
}
