import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/product_category/domain/entities/product_category.dart';
import 'package:tryzeon/feature/common/product_category/domain/repositories/product_category_repository.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product_analysis_result.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product_image_analysis.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_image_analyzer.dart';
import 'package:tryzeon/feature/store/product/domain/usecases/analyze_product_image.dart';
import 'package:typed_result/typed_result.dart';

class _FakeAnalyzer implements ProductImageAnalyzer {
  _FakeAnalyzer(this.result);

  final Result<ProductAnalysisResult, Failure> result;

  @override
  Future<Result<ProductAnalysisResult, Failure>> analyze(
    final File image,
  ) async => result;
}

class _FakeCategoryRepository implements ProductCategoryRepository {
  _FakeCategoryRepository(this.result);

  final Result<List<ProductCategory>, Failure> result;
  int calls = 0;

  @override
  Future<Result<List<ProductCategory>, Failure>> getProductCategories({
    final bool forceRefresh = false,
  }) async {
    calls++;
    return result;
  }
}

const _top = ProductCategory(
  id: 'cat-top',
  code: 'tee',
  name: 'T 恤',
  defaultGarmentType: GarmentType.top,
);

void main() {
  final image = File('main.jpg');

  Future<Result<ProductImageAnalysis, Failure>> analyze(
    final Result<ProductAnalysisResult, Failure> analyzed, {
    final Result<List<ProductCategory>, Failure> categories = const Ok([_top]),
  }) => AnalyzeProductImage(
    _FakeAnalyzer(analyzed),
    _FakeCategoryRepository(categories),
  )(image);

  test('resolves the analyzed category id to its category', () async {
    final result = await analyze(
      const Ok(ProductAnalysisResult(name: '上衣', categoryId: 'cat-top')),
    );

    expect(
      result.get(),
      const ProductImageAnalysis(
        attributes: ProductAnalysisResult(name: '上衣', categoryId: 'cat-top'),
        category: _top,
      ),
    );
  });

  test('an unknown category id leaves the category empty', () async {
    final result = await analyze(
      const Ok(ProductAnalysisResult(categoryId: 'cat-unknown')),
    );

    expect(result.get()?.category, isNull);
  });

  test('skips the category lookup when none was analyzed', () async {
    final categories = _FakeCategoryRepository(const Ok([_top]));

    final result = await AnalyzeProductImage(
      _FakeAnalyzer(const Ok(ProductAnalysisResult(name: '上衣'))),
      categories,
    )(image);

    expect(result.get()?.category, isNull);
    expect(categories.calls, 0);
  });

  test('a category failure still returns the analysis', () async {
    final result = await analyze(
      const Ok(ProductAnalysisResult(name: '上衣', categoryId: 'cat-top')),
      categories: const Err(NetworkFailure()),
    );

    expect(
      result.get(),
      const ProductImageAnalysis(
        attributes: ProductAnalysisResult(name: '上衣', categoryId: 'cat-top'),
      ),
    );
  });

  test('an analysis failure is returned as is', () async {
    final result = await analyze(const Err(ServerFailure()));

    expect(result.getError(), const ServerFailure());
  });
}
