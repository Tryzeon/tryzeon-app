import 'package:json_annotation/json_annotation.dart';

part 'size_measurements_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class SizeMeasurementsModel {
  const SizeMeasurementsModel({
    this.height,
    this.chest,
    this.waist,
    this.hips,
    this.shoulder,
    this.sleeve,
    this.heightOffset,
    this.chestOffset,
    this.waistOffset,
    this.hipsOffset,
    this.shoulderOffset,
    this.sleeveOffset,
  });

  factory SizeMeasurementsModel.fromJson(final Map<String, dynamic> json) =>
      _$SizeMeasurementsModelFromJson(json);

  final double? height;
  final double? chest;
  final double? waist;
  final double? hips;
  final double? shoulder;
  final double? sleeve;
  final double? heightOffset;
  final double? chestOffset;
  final double? waistOffset;
  final double? hipsOffset;
  final double? shoulderOffset;
  final double? sleeveOffset;

  Map<String, dynamic> toJson() => _$SizeMeasurementsModelToJson(this);
}
