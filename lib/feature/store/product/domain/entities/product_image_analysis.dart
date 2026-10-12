import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/common/product_category/domain/entities/product_category.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product_analysis_result.dart';

part 'product_image_analysis.freezed.dart';

@freezed
sealed class ProductImageAnalysis with _$ProductImageAnalysis {
  const factory ProductImageAnalysis({
    required final ProductAnalysisResult attributes,
    final ProductCategory? category,
  }) = _ProductImageAnalysis;
}
