import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';

part 'label_result_dto.g.dart';

@JsonSerializable(
  fieldRename: FieldRename.snake,
  createToJson: false,
  checked: true,
)
class LabelResultDto {
  const LabelResultDto({required this.tags, this.garmentType});

  factory LabelResultDto.fromJson(final Map<String, dynamic> json) =>
      _$LabelResultDtoFromJson(json);

  final List<String> tags;
  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  final GarmentType? garmentType;
}
