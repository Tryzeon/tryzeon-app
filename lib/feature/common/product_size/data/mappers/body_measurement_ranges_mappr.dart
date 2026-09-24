import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';

import '../../domain/entities/body_measurement_ranges.dart';
import '../collections/body_measurement_ranges_embedded.dart';
import '../collections/measurement_range_embedded.dart';
import '../dtos/body_measurement_ranges_dto.dart';
import '../dtos/measurement_range_dto.dart';
import 'body_measurement_ranges_mappr.auto_mappr.dart';

@AutoMappr([
  MapType<MeasurementRangeDto, MeasurementRange>(),
  MapType<MeasurementRange, MeasurementRangeDto>(),
  MapType<MeasurementRange, MeasurementRangeEmbedded>(),
  MapType<MeasurementRangeEmbedded, MeasurementRange>(),
  MapType<BodyMeasurementRangesDto, BodyMeasurementRanges>(),
  MapType<BodyMeasurementRanges, BodyMeasurementRangesDto>(),
  MapType<BodyMeasurementRanges, BodyMeasurementRangesEmbedded>(),
  MapType<BodyMeasurementRangesEmbedded, BodyMeasurementRanges>(),
])
class BodyMeasurementRangesMappr extends $BodyMeasurementRangesMappr {
  const BodyMeasurementRangesMappr();
}
