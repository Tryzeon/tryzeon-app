import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/product_size/data/dtos/body_measurement_ranges_dto.dart';
import 'package:tryzeon/feature/store/product/domain/entities/spoken_unit.dart';

part 'parse_size_voice_response_dto.g.dart';

@JsonSerializable(createToJson: false, checked: true)
class ParseSizeVoiceResponseDto {
  const ParseSizeVoiceResponseDto({required this.sizes});

  factory ParseSizeVoiceResponseDto.fromJson(final Map<String, dynamic> json) =>
      _$ParseSizeVoiceResponseDtoFromJson(json);

  final List<ParsedSizeDto> sizes;
}

/// Keys of [garmentMeasurements] are `GarmentMeasurementType` values; a key
/// this client does not know yet is dropped when mapping to the entity.
@JsonSerializable(
  fieldRename: FieldRename.snake,
  createToJson: false,
  checked: true,
)
class ParsedSizeDto {
  const ParsedSizeDto({
    required this.name,
    required this.garmentMeasurements,
    required this.bodyMeasurementRanges,
  });

  factory ParsedSizeDto.fromJson(final Map<String, dynamic> json) =>
      _$ParsedSizeDtoFromJson(json);

  final String name;
  final Map<String, ParsedMeasurementDto> garmentMeasurements;
  final BodyMeasurementRangesDto bodyMeasurementRanges;
}

@JsonSerializable(createToJson: false, checked: true)
class ParsedMeasurementDto {
  const ParsedMeasurementDto({required this.value, required this.unit});

  factory ParsedMeasurementDto.fromJson(final Map<String, dynamic> json) =>
      _$ParsedMeasurementDtoFromJson(json);

  final double value;
  final SpokenUnit unit;
}
