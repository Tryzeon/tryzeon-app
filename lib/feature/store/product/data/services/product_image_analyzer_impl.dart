import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/data/dtos/image_analysis_request.dart';
import 'package:tryzeon/core/data/utils/decode_function_response.dart';
import 'package:tryzeon/core/data/utils/encode_image_for_analysis.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/store/data/mappers/store_mappr.dart';
import 'package:tryzeon/feature/store/product/data/dtos/product_analysis_result_dto.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product_analysis_result.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_image_analyzer.dart';
import 'package:typed_result/typed_result.dart';

class ProductImageAnalyzerImpl implements ProductImageAnalyzer {
  ProductImageAnalyzerImpl(
    this._supabase, {
    final ImageEncoder encodeImage = encodeImageForAnalysis,
  }) : _encodeImage = encodeImage;

  final SupabaseClient _supabase;
  final ImageEncoder _encodeImage;
  static const _analyzeProductImageFunction = 'analyze-product-image';
  static const _timeout = Duration(seconds: 20);
  static const _mappr = StoreMappr();

  @override
  Future<Result<ProductAnalysisResult, Failure>> analyze(
    final File image,
  ) async {
    try {
      final base64 = await _encodeImage(image);
      if (base64 == null) return const Ok(ProductAnalysisResult());

      final response = await _supabase.functions
          .invoke(
            _analyzeProductImageFunction,
            body: ImageAnalysisRequest(base64: base64).toJson(),
          )
          .timeout(_timeout);

      final dto = decodeFunctionResponse(
        response.data,
        ProductAnalysisResultDto.fromJson,
      );
      return Ok(
        _mappr.convert<ProductAnalysisResultDto, ProductAnalysisResult>(dto),
      );
    } catch (e, stackTrace) {
      AppLogger.warning('Product image analysis failed', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
