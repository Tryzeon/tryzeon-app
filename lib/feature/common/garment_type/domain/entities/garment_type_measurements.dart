import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/garment_measurement_type.dart';

export 'package:tryzeon/feature/common/product_size/domain/entities/garment_measurement_type.dart';

extension GarmentTypeMeasurements on GarmentType {
  List<GarmentMeasurementType> get measurementTypes => switch (this) {
    GarmentType.top || GarmentType.outerwear => const [
      GarmentMeasurementType.shoulderWidth,
      GarmentMeasurementType.sleeveLength,
      GarmentMeasurementType.chestCircumference,
      GarmentMeasurementType.length,
    ],
    GarmentType.dress => const [
      GarmentMeasurementType.shoulderWidth,
      GarmentMeasurementType.sleeveLength,
      GarmentMeasurementType.chestCircumference,
      GarmentMeasurementType.waistCircumference,
      GarmentMeasurementType.hipCircumference,
      GarmentMeasurementType.thighCircumference,
      GarmentMeasurementType.legOpening,
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
      GarmentMeasurementType.legOpening,
    ],
    GarmentType.others => GarmentMeasurementType.values,
  };
}
