import 'package:tryzeon/feature/common/body_measurements/domain/entities/body_measurement_type.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/garment_measurement_type.dart';

/// The garment dimension whose ease against this body dimension says how the
/// garment sits. `null` means no garment measurement can say that — height and
/// weight are only ever judged against a store's published body measurement range. Sleeve,
/// body length and leg opening have no body counterpart in the other
/// direction: they are displayed, not compared.
extension BodyFitDimension on BodyMeasurementType {
  GarmentMeasurementType? get comparableGarmentType => switch (this) {
    BodyMeasurementType.shoulder => GarmentMeasurementType.shoulderWidth,
    BodyMeasurementType.chest => GarmentMeasurementType.chestCircumference,
    BodyMeasurementType.waist => GarmentMeasurementType.waistCircumference,
    BodyMeasurementType.hips => GarmentMeasurementType.hipCircumference,
    BodyMeasurementType.thigh => GarmentMeasurementType.thighCircumference,
    BodyMeasurementType.height => null,
    BodyMeasurementType.weight => null,
  };
}
