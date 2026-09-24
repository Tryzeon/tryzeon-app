import 'package:json_annotation/json_annotation.dart';

part 'garment_measurements_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class GarmentMeasurementsDto {
  const GarmentMeasurementsDto({
    this.shoulderWidth,
    this.chestCircumference,
    this.sleeveLength,
    this.waistCircumference,
    this.hipCircumference,
    this.thighCircumference,
    this.length,
    this.legOpening,
  });

  factory GarmentMeasurementsDto.fromJson(final Map<String, dynamic> json) =>
      _$GarmentMeasurementsDtoFromJson(json);

  final double? shoulderWidth;
  final double? chestCircumference;
  final double? sleeveLength;
  final double? waistCircumference;
  final double? hipCircumference;
  final double? thighCircumference;
  final double? length;
  final double? legOpening;

  Map<String, dynamic> toJson() => _$GarmentMeasurementsDtoToJson(this);
}
