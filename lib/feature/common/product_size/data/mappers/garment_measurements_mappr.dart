import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/feature/common/product_size/data/collections/garment_measurements_embedded.dart';
import 'package:tryzeon/feature/common/product_size/data/dtos/garment_measurements_dto.dart';
import 'package:tryzeon/feature/common/product_size/data/mappers/garment_measurements_mappr.auto_mappr.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/garment_measurements.dart';

@AutoMappr([
  MapType<GarmentMeasurementsDto, GarmentMeasurements>(),
  MapType<GarmentMeasurements, GarmentMeasurementsDto>(),
  MapType<GarmentMeasurements, GarmentMeasurementsEmbedded>(),
  MapType<GarmentMeasurementsEmbedded, GarmentMeasurements>(),
])
class GarmentMeasurementsMappr extends $GarmentMeasurementsMappr {
  const GarmentMeasurementsMappr();
}
