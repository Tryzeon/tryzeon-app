import 'package:json_annotation/json_annotation.dart';

part 'body_measurements_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class BodyMeasurementsDto {
  const BodyMeasurementsDto({
    this.height,
    this.weight,
    this.shoulder,
    this.chest,
    this.waist,
    this.hips,
    this.thigh,
  });

  factory BodyMeasurementsDto.fromJson(final Map<String, dynamic> json) =>
      _$BodyMeasurementsDtoFromJson(json);

  final double? height;
  final double? weight;
  final double? shoulder;
  final double? chest;
  final double? waist;
  final double? hips;
  final double? thigh;

  Map<String, dynamic> toJson() => _$BodyMeasurementsDtoToJson(this);
}
