import 'package:tryzeon/feature/common/measurement/presentation/formatters/measurement_value_format.dart';

import '../../domain/entities/measurement_range.dart';

export '../../domain/entities/measurement_range.dart';

extension MeasurementRangeUiMapper on MeasurementRange {
  String get display => '${formatMeasurementValue(min)}–${formatMeasurementValue(max)}';
}
