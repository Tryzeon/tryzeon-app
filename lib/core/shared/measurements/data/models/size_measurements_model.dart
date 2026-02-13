import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/core/shared/measurements/collections/size_measurements_collection.dart';
import 'package:tryzeon/core/shared/measurements/entities/size_measurements.dart';

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

  factory SizeMeasurementsModel.fromCollection(
    final SizeMeasurementsCollection collection,
  ) {
    return SizeMeasurementsModel(
      height: collection.height,
      chest: collection.chest,
      waist: collection.waist,
      hips: collection.hips,
      shoulder: collection.shoulder,
      sleeve: collection.sleeve,
      heightOffset: collection.heightOffset,
      chestOffset: collection.chestOffset,
      waistOffset: collection.waistOffset,
      hipsOffset: collection.hipsOffset,
      shoulderOffset: collection.shoulderOffset,
      sleeveOffset: collection.sleeveOffset,
    );
  }

  factory SizeMeasurementsModel.fromEntity(final SizeMeasurements entity) {
    return SizeMeasurementsModel(
      height: entity.height,
      chest: entity.chest,
      waist: entity.waist,
      hips: entity.hips,
      shoulder: entity.shoulder,
      sleeve: entity.sleeve,
      heightOffset: entity.heightOffset,
      chestOffset: entity.chestOffset,
      waistOffset: entity.waistOffset,
      hipsOffset: entity.hipsOffset,
      shoulderOffset: entity.shoulderOffset,
      sleeveOffset: entity.sleeveOffset,
    );
  }

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

  SizeMeasurementsCollection toCollection() {
    return SizeMeasurementsCollection()
      ..height = height
      ..chest = chest
      ..waist = waist
      ..hips = hips
      ..shoulder = shoulder
      ..sleeve = sleeve
      ..heightOffset = heightOffset
      ..chestOffset = chestOffset
      ..waistOffset = waistOffset
      ..hipsOffset = hipsOffset
      ..shoulderOffset = shoulderOffset
      ..sleeveOffset = sleeveOffset;
  }

  SizeMeasurements toEntity() {
    return SizeMeasurements(
      height: height,
      chest: chest,
      waist: waist,
      hips: hips,
      shoulder: shoulder,
      sleeve: sleeve,
      heightOffset: heightOffset,
      chestOffset: chestOffset,
      waistOffset: waistOffset,
      hipsOffset: hipsOffset,
      shoulderOffset: shoulderOffset,
      sleeveOffset: sleeveOffset,
    );
  }
}
