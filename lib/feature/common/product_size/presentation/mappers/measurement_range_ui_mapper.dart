import 'package:tryzeon/feature/common/measurement/presentation/formatters/measurement_value_format.dart';

import 'package:tryzeon/feature/common/product_size/domain/entities/measurement_range.dart';

export 'package:tryzeon/feature/common/product_size/domain/entities/measurement_range.dart';

extension MeasurementRangeUiMapper on MeasurementRange {
  String get display =>
      '${formatMeasurementValue(min)}–${formatMeasurementValue(max)}';
}
