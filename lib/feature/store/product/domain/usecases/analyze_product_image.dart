import 'dart:io';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/product_category/domain/repositories/product_category_repository.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product_image_analysis.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_image_analyzer.dart';
import 'package:typed_result/typed_result.dart';

class AnalyzeProductImage {
  AnalyzeProductImage(this._analyzer, this._categoryRepository);

  final ProductImageAnalyzer _analyzer;
  final ProductCategoryRepository _categoryRepository;

  /// Categories only refine the pre-fill, so failing to load them still
  /// returns the analysis — without a category.
  Future<Result<ProductImageAnalysis, Failure>> call(final File image) async {
    final analyzed = await _analyzer.analyze(image);
    if (analyzed.isFailure) return Err(analyzed.getError()!);
    final attributes = analyzed.get()!;

    final categoryId = attributes.categoryId;
    if (categoryId == null) {
      return Ok(ProductImageAnalysis(attributes: attributes));
    }

    final categories = await _categoryRepository.getProductCategories();
    return Ok(
      ProductImageAnalysis(
        attributes: attributes,
        category: categories
            .get()
            ?.where((final c) => c.id == categoryId)
            .firstOrNull,
      ),
    );
  }
}
