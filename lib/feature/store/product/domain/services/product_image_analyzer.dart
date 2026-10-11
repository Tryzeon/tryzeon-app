import 'dart:io';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product_analysis_result.dart';
import 'package:typed_result/typed_result.dart';

abstract interface class ProductImageAnalyzer {
  Future<Result<ProductAnalysisResult, Failure>> analyze(final File image);
}
