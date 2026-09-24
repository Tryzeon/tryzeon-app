import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/product_size/data/dtos/measurement_range_dto.dart';

part 'body_measurement_ranges_dto.g.dart';

@JsonSerializable(
  fieldRename: FieldRename.snake,
  includeIfNull: false,
  explicitToJson: true,
)
class BodyMeasurementRangesDto {
  const BodyMeasurementRangesDto({
    this.height,
    this.weight,
    this.shoulder,
    this.chest,
    this.waist,
    this.hips,
    this.thigh,
  });

  factory BodyMeasurementRangesDto.fromJson(final Map<String, dynamic> json) =>
      _$BodyMeasurementRangesDtoFromJson(json);

  final MeasurementRangeDto? height;
  final MeasurementRangeDto? weight;
  final MeasurementRangeDto? shoulder;
  final MeasurementRangeDto? chest;
  final MeasurementRangeDto? waist;
  final MeasurementRangeDto? hips;
  final MeasurementRangeDto? thigh;

  Map<String, dynamic> toJson() => _$BodyMeasurementRangesDtoToJson(this);
}
