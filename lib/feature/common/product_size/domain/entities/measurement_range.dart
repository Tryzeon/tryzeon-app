import 'package:freezed_annotation/freezed_annotation.dart';

part 'measurement_range.freezed.dart';

/// An inclusive `[min, max]` band, in the unit of whatever dimension it bounds.
@freezed
sealed class MeasurementRange with _$MeasurementRange {
  const factory MeasurementRange({required final double min, required final double max}) =
      _MeasurementRange;
  const MeasurementRange._();

  double get center => (min + max) / 2;

  bool contains(final double value) => value >= min && value <= max;

  /// Zero inside the range, otherwise how far outside the nearer bound.
  double distanceOutside(final double value) {
    if (value < min) return min - value;
    if (value > max) return value - max;
    return 0;
  }
}
