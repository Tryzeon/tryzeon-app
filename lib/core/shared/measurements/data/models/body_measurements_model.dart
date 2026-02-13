import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/core/shared/measurements/collections/body_measurements_collection.dart';
import 'package:tryzeon/core/shared/measurements/entities/body_measurements.dart';

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

  factory BodyMeasurementsModel.fromCollection(
    final BodyMeasurementsCollection collection,
  ) {
    return BodyMeasurementsModel(
      height: collection.height,
      chest: collection.chest,
      waist: collection.waist,
      hips: collection.hips,
      shoulder: collection.shoulder,
      sleeve: collection.sleeve,
    );
  }

  factory BodyMeasurementsModel.fromEntity(final BodyMeasurements entity) {
    return BodyMeasurementsModel(
      height: entity.height,
      chest: entity.chest,
      waist: entity.waist,
      hips: entity.hips,
      shoulder: entity.shoulder,
      sleeve: entity.sleeve,
    );
  }

  factory BodyMeasurementsModel.fromJson(final Map<String, dynamic> json) =>
      _$BodyMeasurementsModelFromJson(json);

  final double? height;
  final double? chest;
  final double? waist;
  final double? hips;
  final double? shoulder;
  final double? sleeve;

  Map<String, dynamic> toJson() => _$BodyMeasurementsModelToJson(this);

  BodyMeasurementsCollection toCollection() {
    return BodyMeasurementsCollection()
      ..height = height
      ..chest = chest
      ..waist = waist
      ..hips = hips
      ..shoulder = shoulder
      ..sleeve = sleeve;
  }

  BodyMeasurements toEntity() {
    return BodyMeasurements(
      height: height,
      chest: chest,
      waist: waist,
      hips: hips,
      shoulder: shoulder,
      sleeve: sleeve,
    );
  }
}
