import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/garment_measurement_type.dart';

export 'package:tryzeon/feature/common/product_size/domain/entities/garment_measurement_type.dart';

extension GarmentTypeMeasurements on GarmentType {
  List<GarmentMeasurementType> get measurementTypes => switch (this) {
    GarmentType.top || GarmentType.outerwear || GarmentType.dress => const [
      GarmentMeasurementType.sleeveLength,
      GarmentMeasurementType.shoulderWidth,
      GarmentMeasurementType.chestCircumference,
      GarmentMeasurementType.length,
    ],
    GarmentType.skirt => const [
      GarmentMeasurementType.waistCircumference,
      GarmentMeasurementType.hipCircumference,
      GarmentMeasurementType.length,
    ],
    GarmentType.pants => const [
      GarmentMeasurementType.waistCircumference,
      GarmentMeasurementType.hipCircumference,
      GarmentMeasurementType.thighCircumference,
      GarmentMeasurementType.length,
    ],
    GarmentType.others => GarmentMeasurementType.values,
  };
}
