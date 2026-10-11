import 'dart:io';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product_analysis_result.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_image_analyzer.dart';
import 'package:typed_result/typed_result.dart';

class AnalyzeProductImage {
  AnalyzeProductImage(this._analyzer);

  final ProductImageAnalyzer _analyzer;

  Future<Result<ProductAnalysisResult, Failure>> call(final File image) =>
      _analyzer.analyze(image);
}
