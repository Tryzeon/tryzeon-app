import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/feature/common/body_measurements/data/collections/body_measurements_embedded.dart';
import 'package:tryzeon/feature/common/body_measurements/data/dtos/body_measurements_dto.dart';
import 'package:tryzeon/feature/common/body_measurements/data/mappers/body_measurements_mappr.auto_mappr.dart';
import 'package:tryzeon/feature/common/body_measurements/domain/entities/body_measurements.dart';

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
