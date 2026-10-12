import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/data/dtos/image_analysis_request.dart';
import 'package:tryzeon/core/data/errors/map_exception_to_failure.dart';
import 'package:tryzeon/core/data/utils/decode_function_response.dart';
import 'package:tryzeon/core/data/utils/encode_image_for_analysis.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/dtos/label_result_dto.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/mappers/wardrobe_mappr.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/label_result.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/services/label_tagger.dart';
import 'package:typed_result/typed_result.dart';

class LabelTaggerImpl implements LabelTagger {
  LabelTaggerImpl(
    this._supabase, {
    final ImageEncoder encodeImage = encodeImageForAnalysis,
  }) : _encodeImage = encodeImage;

  final SupabaseClient _supabase;
  final ImageEncoder _encodeImage;
  static const _analyzeWardrobeImageFunction = 'analyze-wardrobe-image';
  static const _timeout = Duration(seconds: 20);
  static const _mappr = WardrobeMappr();

  @override
  Future<Result<LabelResult, Failure>> analyze(final File image) async {
    try {
      final base64 = await _encodeImage(image);
      if (base64 == null) return const Ok(LabelResult());

      final response = await _supabase.functions
          .invoke(
            _analyzeWardrobeImageFunction,
            body: ImageAnalysisRequest(base64: base64).toJson(),
          )
          .timeout(_timeout);

      final dto = decodeFunctionResponse(
        response.data,
        LabelResultDto.fromJson,
      );
      return Ok(_mappr.convert<LabelResultDto, LabelResult>(dto));
    } catch (e, stackTrace) {
      AppLogger.warning('Wardrobe label tagging failed', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
