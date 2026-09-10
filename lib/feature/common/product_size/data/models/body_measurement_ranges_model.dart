import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/product_size/data/models/measurement_range_model.dart';

part 'body_measurement_ranges_model.g.dart';

@JsonSerializable(
  fieldRename: FieldRename.snake,
  includeIfNull: false,
  explicitToJson: true,
)
class BodyMeasurementRangesModel {
  const BodyMeasurementRangesModel({
    this.height,
    this.weight,
    this.shoulder,
    this.chest,
    this.waist,
    this.hips,
    this.thigh,
  });

  factory BodyMeasurementRangesModel.fromJson(final Map<String, dynamic> json) =>
      _$BodyMeasurementRangesModelFromJson(json);

  final MeasurementRangeModel? height;
  final MeasurementRangeModel? weight;
  final MeasurementRangeModel? shoulder;
  final MeasurementRangeModel? chest;
  final MeasurementRangeModel? waist;
  final MeasurementRangeModel? hips;
  final MeasurementRangeModel? thigh;

  Map<String, dynamic> toJson() => _$BodyMeasurementRangesModelToJson(this);
}
