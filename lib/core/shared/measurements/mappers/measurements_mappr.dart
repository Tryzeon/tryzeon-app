import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';

import '../collections/body_measurements_collection.dart';
import '../collections/size_measurements_collection.dart';
import '../data/models/body_measurements_model.dart';
import '../data/models/size_measurements_model.dart';
import '../entities/body_measurements.dart';
import '../entities/size_measurements.dart';
import 'measurements_mappr.auto_mappr.dart';

/// AutoMappr configuration for Measurements module
/// Handles bidirectional mapping between Entity ↔ Model ↔ Collection layers
@AutoMappr([
  // BodyMeasurements mappings
  MapType<BodyMeasurementsModel, BodyMeasurements>(),
  MapType<BodyMeasurements, BodyMeasurementsModel>(),
  MapType<BodyMeasurementsModel, BodyMeasurementsCollection>(),
  MapType<BodyMeasurementsCollection, BodyMeasurementsModel>(),

  // SizeMeasurements mappings
  MapType<SizeMeasurementsModel, SizeMeasurements>(),
  MapType<SizeMeasurements, SizeMeasurementsModel>(),
  MapType<SizeMeasurementsModel, SizeMeasurementsCollection>(),
  MapType<SizeMeasurementsCollection, SizeMeasurementsModel>(),
])
class MeasurementsMappr extends $MeasurementsMappr {
  const MeasurementsMappr();
}
