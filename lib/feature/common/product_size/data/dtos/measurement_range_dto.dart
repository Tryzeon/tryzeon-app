import 'package:json_annotation/json_annotation.dart';

part 'measurement_range_dto.g.dart';

@JsonSerializable()
class MeasurementRangeDto {
  const MeasurementRangeDto({required this.min, required this.max});

  factory MeasurementRangeDto.fromJson(final Map<String, dynamic> json) =>
      _$MeasurementRangeDtoFromJson(json);

  final double min;
  final double max;

  Map<String, dynamic> toJson() => _$MeasurementRangeDtoToJson(this);
}
