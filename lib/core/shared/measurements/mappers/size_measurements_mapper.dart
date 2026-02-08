import 'package:tryzeon/core/shared/measurements/collections/size_measurements_collection.dart';
import 'package:tryzeon/core/shared/measurements/entities/size_measurements.dart';

/// Extension to map SizeMeasurements entity to SizeMeasurementsCollection
extension SizeMeasurementsEntityMapper on SizeMeasurements {
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
}

/// Extension to map SizeMeasurementsCollection to SizeMeasurements entity
extension SizeMeasurementsCollectionMapper on SizeMeasurementsCollection {
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
