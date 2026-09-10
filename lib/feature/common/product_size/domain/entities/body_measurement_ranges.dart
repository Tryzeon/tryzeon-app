import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/common/body_measurements/domain/entities/body_measurement_type.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/measurement_range.dart';

export 'package:tryzeon/feature/common/body_measurements/domain/entities/body_measurement_type.dart';
export 'package:tryzeon/feature/common/product_size/domain/entities/measurement_range.dart';

part 'body_measurement_ranges.freezed.dart';

/// The body a size is published as fitting — the *wearer's* dimensions, as
/// opposed to [GarmentMeasurements] which are the garment's own. Keyed by
/// [BodyMeasurementType] so each range lines up with the shopper's recorded
/// value of the same type and inherits its unit (cm, or kg for weight).
@freezed
sealed class BodyMeasurementRanges with _$BodyMeasurementRanges {
  const factory BodyMeasurementRanges({
    final MeasurementRange? height,
    final MeasurementRange? weight,
    final MeasurementRange? shoulder,
    final MeasurementRange? chest,
    final MeasurementRange? waist,
    final MeasurementRange? hips,
    final MeasurementRange? thigh,
  }) = _BodyMeasurementRanges;
  const BodyMeasurementRanges._();

  factory BodyMeasurementRanges.fromValues(
    final Map<BodyMeasurementType, MeasurementRange?> values,
  ) => BodyMeasurementRanges(
    height: values[BodyMeasurementType.height],
    weight: values[BodyMeasurementType.weight],
    shoulder: values[BodyMeasurementType.shoulder],
    chest: values[BodyMeasurementType.chest],
    waist: values[BodyMeasurementType.waist],
    hips: values[BodyMeasurementType.hips],
    thigh: values[BodyMeasurementType.thigh],
  );

  MeasurementRange? getValue(final BodyMeasurementType type) => switch (type) {
    BodyMeasurementType.height => height,
    BodyMeasurementType.weight => weight,
    BodyMeasurementType.shoulder => shoulder,
    BodyMeasurementType.chest => chest,
    BodyMeasurementType.waist => waist,
    BodyMeasurementType.hips => hips,
    BodyMeasurementType.thigh => thigh,
  };

  MeasurementRange? operator [](final BodyMeasurementType type) => getValue(type);

  bool get isEmpty => BodyMeasurementType.values.every((final t) => getValue(t) == null);
}

/// The wearer dimensions a store can publish a range for. Height and weight
/// have no garment counterpart, so a range is the only way a size chart can
/// speak to them; circumference ranges are supported by the type but not yet
/// offered in the editor.
const List<BodyMeasurementType> bodyMeasurementRangeTypes = [
  BodyMeasurementType.height,
  BodyMeasurementType.weight,
];
