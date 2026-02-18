import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/shared/measurements/entities/measurement_type.dart';

export 'package:tryzeon/core/shared/measurements/entities/measurement_type.dart';

part 'body_measurements.freezed.dart';
part 'body_measurements.g.dart';

@freezed
sealed class BodyMeasurements with _$BodyMeasurements {
  const factory BodyMeasurements({
    final double? height,
    final double? chest,
    final double? waist,
    final double? hips,
    final double? shoulder,
    final double? sleeve,
  }) = _BodyMeasurements;
  const BodyMeasurements._();

  factory BodyMeasurements.fromJson(final Map<String, dynamic> json) =>
      _$BodyMeasurementsFromJson(json);

  @override
  Map<String, dynamic> toJson() {
    return {for (final type in MeasurementType.values) type.value: this[type]};
  }

  // / 透過 Enum 動態取得數值
  double? operator [](final MeasurementType type) => switch (type) {
    MeasurementType.height => height,
    MeasurementType.chest => chest,
    MeasurementType.waist => waist,
    MeasurementType.hips => hips,
    MeasurementType.shoulder => shoulder,
    MeasurementType.sleeve => sleeve,
  };
}
