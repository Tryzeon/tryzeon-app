import 'package:json_annotation/json_annotation.dart';

part 'measurement_range_model.g.dart';

@JsonSerializable()
class MeasurementRangeModel {
  const MeasurementRangeModel({required this.min, required this.max});

  factory MeasurementRangeModel.fromJson(final Map<String, dynamic> json) =>
      _$MeasurementRangeModelFromJson(json);

  final double min;
  final double max;

  Map<String, dynamic> toJson() => _$MeasurementRangeModelToJson(this);
}
