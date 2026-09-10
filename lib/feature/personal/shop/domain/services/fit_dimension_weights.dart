import 'package:tryzeon/feature/common/body_measurements/domain/entities/body_measurement_type.dart';

/// How much each body dimension counts when ranking sizes. Circumferences
/// drive fit; shoulder width and thigh are less decisive; height and weight
/// are the store's coarse guidance and must not outvote a measured
/// circumference.
class FitDimensionWeights {
  FitDimensionWeights._();

  static const Map<BodyMeasurementType, double> _weights = {
    BodyMeasurementType.chest: 1,
    BodyMeasurementType.waist: 1,
    BodyMeasurementType.hips: 1,
    BodyMeasurementType.shoulder: 0.8,
    BodyMeasurementType.thigh: 0.8,
    BodyMeasurementType.height: 0.5,
    BodyMeasurementType.weight: 0.5,
  };

  static double weightFor(final BodyMeasurementType type) => _weights[type] ?? 1;
}
