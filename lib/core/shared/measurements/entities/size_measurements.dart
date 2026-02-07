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
        data[type.name] = value;
      }
      final offset = getOffset(type);
      if (offset != null) {
        data['${type.name}_offset'] = offset;
      }
    }
    return data;
  }

  double? getValue(final MeasurementType type) {
    switch (type) {
      case MeasurementType.height:
        return height;
      case MeasurementType.chest:
        return chest;
      case MeasurementType.waist:
        return waist;
      case MeasurementType.hips:
        return hips;
      case MeasurementType.shoulder:
        return shoulder;
      case MeasurementType.sleeve:
        return sleeve;
    }
  }

  double? getOffset(final MeasurementType type) {
    switch (type) {
      case MeasurementType.height:
        return heightOffset;
      case MeasurementType.chest:
        return chestOffset;
      case MeasurementType.waist:
        return waistOffset;
      case MeasurementType.hips:
        return hipsOffset;
      case MeasurementType.shoulder:
        return shoulderOffset;
      case MeasurementType.sleeve:
        return sleeveOffset;
    }
  }

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
