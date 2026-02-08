import 'package:tryzeon/core/shared/measurements/collections/body_measurements_collection.dart';
import 'package:tryzeon/core/shared/measurements/entities/body_measurements.dart';

/// Extension to map BodyMeasurements entity to BodyMeasurementsCollection
extension BodyMeasurementsEntityMapper on BodyMeasurements {
  BodyMeasurementsCollection toCollection() {
    return BodyMeasurementsCollection()
      ..height = height
      ..chest = chest
      ..waist = waist
      ..hips = hips
      ..shoulder = shoulder
      ..sleeve = sleeve;
  }
}

/// Extension to map BodyMeasurementsCollection to BodyMeasurements entity
extension BodyMeasurementsCollectionMapper on BodyMeasurementsCollection {
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
