import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';

import '../../domain/entities/body_measurement_ranges.dart';
import '../collections/body_measurement_ranges_embedded.dart';
import '../collections/measurement_range_embedded.dart';
import '../models/body_measurement_ranges_model.dart';
import '../models/measurement_range_model.dart';
import 'body_measurement_ranges_mappr.auto_mappr.dart';

@AutoMappr([
  MapType<MeasurementRangeModel, MeasurementRange>(),
  MapType<MeasurementRange, MeasurementRangeModel>(),
  MapType<MeasurementRangeModel, MeasurementRangeEmbedded>(),
  MapType<MeasurementRangeEmbedded, MeasurementRangeModel>(),
  MapType<BodyMeasurementRangesModel, BodyMeasurementRanges>(),
  MapType<BodyMeasurementRanges, BodyMeasurementRangesModel>(),
  MapType<BodyMeasurementRangesModel, BodyMeasurementRangesEmbedded>(),
  MapType<BodyMeasurementRangesEmbedded, BodyMeasurementRangesModel>(),
])
class BodyMeasurementRangesMappr extends $BodyMeasurementRangesMappr {
  const BodyMeasurementRangesMappr();
}
