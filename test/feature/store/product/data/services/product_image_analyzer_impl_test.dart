import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/data/services/image_analysis_api.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/store/product/data/services/product_image_analyzer_impl.dart';
import 'package:typed_result/typed_result.dart';

class _FakeApi implements ImageAnalysisApi {
  _FakeApi({this.data, this.error});

  final Map<String, dynamic>? data;
  final Object? error;

  @override
  Future<Map<String, dynamic>?> analyze({
    required final File image,
    required final String functionName,
  }) async {
    if (error case final error?) throw error;
    return data;
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  test('parses the analysis into a result', () async {
    final result = await ProductImageAnalyzerImpl(
      _FakeApi(data: {'name': '碎花洋裝'}),
    ).analyze(File('a.jpg'));

    expect(result.get()?.name, '碎花洋裝');
  });

  test('a failed analysis is reported as a failure', () async {
    final result = await ProductImageAnalyzerImpl(
      _FakeApi(error: const SocketException('offline')),
    ).analyze(File('a.jpg'));

    expect(result.getError(), const NetworkFailure());
  });
}
