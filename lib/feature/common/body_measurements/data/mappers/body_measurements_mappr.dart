import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';

import '../../domain/entities/body_measurements.dart';
import '../collections/body_measurements_embedded.dart';
import '../dtos/body_measurements_dto.dart';
import 'body_measurements_mappr.auto_mappr.dart';

@AutoMappr([
  MapType<BodyMeasurementsDto, BodyMeasurements>(
    whenSourceIsNull: BodyMeasurements(),
  ),
  MapType<BodyMeasurements, BodyMeasurementsDto>(),
  MapType<BodyMeasurements, BodyMeasurementsEmbedded>(),
  MapType<BodyMeasurementsEmbedded, BodyMeasurements>(
    whenSourceIsNull: BodyMeasurements(),
  ),
])
class BodyMeasurementsMappr extends $BodyMeasurementsMappr {
  const BodyMeasurementsMappr();
}
