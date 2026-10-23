import 'package:tryzeon/feature/common/product_size/domain/entities/body_measurement_ranges.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/garment_measurement_type.dart';
import 'package:tryzeon/feature/store/product/domain/entities/spoken_unit.dart';

class ParsedMeasurement {
  const ParsedMeasurement({required this.value, required this.unit});

  final double value;
  final SpokenUnit unit;
}

class ParsedSize {
  const ParsedSize({
    required this.name,
    this.garmentMeasurements = const {},
    this.bodyMeasurementRanges = const {},
  });

  final String name;
  final Map<GarmentMeasurementType, ParsedMeasurement> garmentMeasurements;
  final Map<BodyMeasurementType, MeasurementRange> bodyMeasurementRanges;
}
