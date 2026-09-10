import 'package:isar_community/isar.dart';
import 'package:tryzeon/feature/common/product_size/data/collections/measurement_range_embedded.dart';

part 'body_measurement_ranges_embedded.g.dart';

@embedded
class BodyMeasurementRangesEmbedded {
  MeasurementRangeEmbedded? height;
  MeasurementRangeEmbedded? weight;
  MeasurementRangeEmbedded? shoulder;
  MeasurementRangeEmbedded? chest;
  MeasurementRangeEmbedded? waist;
  MeasurementRangeEmbedded? hips;
  MeasurementRangeEmbedded? thigh;
}
