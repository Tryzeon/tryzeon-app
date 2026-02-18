import 'package:json_annotation/json_annotation.dart';

part 'body_measurements_model.g.dart';

@JsonSerializable()
class BodyMeasurementsModel {
  const BodyMeasurementsModel({
    this.height,
    this.chest,
    this.waist,
    this.hips,
    this.shoulder,
    this.sleeve,
  });

  factory BodyMeasurementsModel.fromJson(final Map<String, dynamic> json) =>
      _$BodyMeasurementsModelFromJson(json);

  final double? height;
  final double? chest;
  final double? waist;
  final double? hips;
  final double? shoulder;
  final double? sleeve;

  Map<String, dynamic> toJson() => _$BodyMeasurementsModelToJson(this);
}
