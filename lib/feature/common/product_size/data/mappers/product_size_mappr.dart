import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/feature/common/product_size/data/collections/body_measurement_ranges_embedded.dart';
import 'package:tryzeon/feature/common/product_size/data/collections/garment_measurements_embedded.dart';
import 'package:tryzeon/feature/common/product_size/data/collections/measurement_range_embedded.dart';
import 'package:tryzeon/feature/common/product_size/data/collections/product_size_embedded.dart';
import 'package:tryzeon/feature/common/product_size/data/dtos/body_measurement_ranges_dto.dart';
import 'package:tryzeon/feature/common/product_size/data/dtos/garment_measurements_dto.dart';
import 'package:tryzeon/feature/common/product_size/data/dtos/measurement_range_dto.dart';
import 'package:tryzeon/feature/common/product_size/data/dtos/product_size_dto.dart';
import 'package:tryzeon/feature/common/product_size/data/mappers/product_size_mappr.auto_mappr.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/product_size.dart';

@AutoMappr([
  MapType<ProductSizeDto, ProductSize>(),
  MapType<ProductSize, ProductSizeDto>(),
  MapType<ProductSize, ProductSizeEmbedded>(),
  MapType<ProductSizeEmbedded, ProductSize>(),

  MapType<GarmentMeasurementsDto, GarmentMeasurements>(),
  MapType<GarmentMeasurements, GarmentMeasurementsDto>(),
  MapType<GarmentMeasurements, GarmentMeasurementsEmbedded>(),
  MapType<GarmentMeasurementsEmbedded, GarmentMeasurements>(),

  MapType<MeasurementRangeDto, MeasurementRange>(),
  MapType<MeasurementRange, MeasurementRangeDto>(),
  MapType<MeasurementRange, MeasurementRangeEmbedded>(),
  MapType<MeasurementRangeEmbedded, MeasurementRange>(),
  MapType<BodyMeasurementRangesDto, BodyMeasurementRanges>(),
  MapType<BodyMeasurementRanges, BodyMeasurementRangesDto>(),
  MapType<BodyMeasurementRanges, BodyMeasurementRangesEmbedded>(),
  MapType<BodyMeasurementRangesEmbedded, BodyMeasurementRanges>(),
])
class ProductSizeMappr extends $ProductSizeMappr {
  const ProductSizeMappr();
}
