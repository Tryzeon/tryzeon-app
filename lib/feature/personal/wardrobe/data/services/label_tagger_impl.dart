import 'dart:io';

import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/data/services/image_analysis_api.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:typed_result/typed_result.dart';

import '../../domain/entities/label_result.dart';
import '../../domain/services/label_tagger.dart';

LabelResult parseAnalysisResponse(final Map<String, dynamic> data) {
  final rawTags = data['tags'];
  final tags = rawTags is List
      ? rawTags.whereType<String>().where((final t) => t.isNotEmpty).toList()
      : <String>[];

  final rawGarmentType = data['garment_type'];
  final garmentType = rawGarmentType is String
      ? GarmentType.tryFromString(rawGarmentType)
      : null;

  return LabelResult(tags: tags, garmentType: garmentType);
}

class LabelTaggerImpl implements LabelTagger {
  LabelTaggerImpl(this._api);

  final ImageAnalysisApi _api;

  @override
  Future<Result<LabelResult, Failure>> analyze(final File image) async {
    try {
      final data = await _api.analyze(
        image: image,
        functionName: AppConstants.functionAnalyzeWardrobeImage,
      );
      if (data == null) return const Ok(LabelResult());
      return Ok(parseAnalysisResponse(data));
    } catch (e, stackTrace) {
      AppLogger.warning('Wardrobe label tagging failed', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
