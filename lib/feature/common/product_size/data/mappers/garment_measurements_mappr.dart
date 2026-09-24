import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';

import '../../domain/entities/garment_measurements.dart';
import '../collections/garment_measurements_embedded.dart';
import '../dtos/garment_measurements_dto.dart';
import 'garment_measurements_mappr.auto_mappr.dart';

@AutoMappr([
  MapType<GarmentMeasurementsDto, GarmentMeasurements>(),
  MapType<GarmentMeasurements, GarmentMeasurementsDto>(),
  MapType<GarmentMeasurementsDto, GarmentMeasurementsEmbedded>(),
  MapType<GarmentMeasurementsEmbedded, GarmentMeasurementsDto>(),
])
class GarmentMeasurementsMappr extends $GarmentMeasurementsMappr {
  const GarmentMeasurementsMappr();
}
