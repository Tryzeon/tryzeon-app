import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';

part 'label_result.freezed.dart';

@freezed
sealed class LabelResult with _$LabelResult {
  const factory LabelResult({
    @Default([]) final List<String> tags,
    final GarmentType? garmentType,
  }) = _LabelResult;
}
