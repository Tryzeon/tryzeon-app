import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';

import '../collections/measurements_collection.dart';
import '../data/models/measurements_model.dart';
import '../entities/measurements.dart';
import 'measurements_mappr.auto_mappr.dart';

/// AutoMappr configuration for shared Measurements
/// Handles Measurements ↔ MeasurementsModel ↔ MeasurementsCollection mappings
@AutoMappr([
  MapType<MeasurementsModel, Measurements>(),
  MapType<Measurements, MeasurementsModel>(),
  MapType<MeasurementsModel, MeasurementsCollection>(),
  MapType<MeasurementsCollection, MeasurementsModel>(),
])
class MeasurementsMappr extends $MeasurementsMappr {
  const MeasurementsMappr();
}
