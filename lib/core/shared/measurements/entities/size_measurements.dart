import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/shared/measurements/entities/measurement_type.dart';

part 'size_measurements.freezed.dart';
part 'size_measurements.g.dart';

@freezed
sealed class SizeMeasurements with _$SizeMeasurements {
  const factory SizeMeasurements({
    final double? height,
    final double? chest,
    final double? waist,
    final double? hips,
    final double? shoulder,
    final double? sleeve,
    final double? heightOffset,
    final double? chestOffset,
    final double? waistOffset,
    final double? hipsOffset,
    final double? shoulderOffset,
    final double? sleeveOffset,
  }) = _SizeMeasurements;
  const SizeMeasurements._();

  factory SizeMeasurements.fromJson(final Map<String, dynamic> json) =>
      _$SizeMeasurementsFromJson(json);

  @override
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    for (final type in MeasurementType.values) {
      final value = getValue(type);
      if (value != null) {
        data[type.value] = value;
      }
      final offset = getOffset(type);
      if (offset != null) {
        data['${type.value}_offset'] = offset;
      }
    }
    return data;
  }

  double? getValue(final MeasurementType type) => switch (type) {
    MeasurementType.height => height,
    MeasurementType.chest => chest,
    MeasurementType.waist => waist,
    MeasurementType.hips => hips,
    MeasurementType.shoulder => shoulder,
    MeasurementType.sleeve => sleeve,
  };

  double? getOffset(final MeasurementType type) => switch (type) {
    MeasurementType.height => heightOffset,
    MeasurementType.chest => chestOffset,
    MeasurementType.waist => waistOffset,
    MeasurementType.hips => hipsOffset,
    MeasurementType.shoulder => shoulderOffset,
    MeasurementType.sleeve => sleeveOffset,
  };

  /// 取得該測量類型的區間範圍 (min, max)
  /// 如果沒有值，回傳 null
  /// 如果沒有 offset，預設為 0
  (double min, double max)? getRange(final MeasurementType type) {
    final value = getValue(type);
    if (value == null) return null;

    final offset = getOffset(type) ?? 0.0;
    return (value - offset, value + offset);
  }
}
