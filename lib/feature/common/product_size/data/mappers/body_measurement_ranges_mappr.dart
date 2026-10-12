import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/feature/common/product_size/data/collections/body_measurement_ranges_embedded.dart';
import 'package:tryzeon/feature/common/product_size/data/collections/measurement_range_embedded.dart';
import 'package:tryzeon/feature/common/product_size/data/dtos/body_measurement_ranges_dto.dart';
import 'package:tryzeon/feature/common/product_size/data/dtos/measurement_range_dto.dart';
import 'package:tryzeon/feature/common/product_size/data/mappers/body_measurement_ranges_mappr.auto_mappr.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/body_measurement_ranges.dart';

@AutoMappr([
  MapType<MeasurementRangeDto, MeasurementRange>(),
  MapType<MeasurementRange, MeasurementRangeDto>(),
  MapType<MeasurementRange, MeasurementRangeEmbedded>(),
  MapType<MeasurementRangeEmbedded, MeasurementRange>(),
  MapType<BodyMeasurementRangesDto, BodyMeasurementRanges>(),
  MapType<BodyMeasurementRanges, BodyMeasurementRangesDto>(),
  MapType<BodyMeasurementRanges, BodyMeasurementRangesEmbedded>(),
  MapType<BodyMeasurementRangesEmbedded, BodyMeasurementRanges>(),
])
class BodyMeasurementRangesMappr extends $BodyMeasurementRangesMappr {
  const BodyMeasurementRangesMappr();
}
