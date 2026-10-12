import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/feature/common/product_size/data/collections/product_size_embedded.dart';
import 'package:tryzeon/feature/common/product_size/data/dtos/product_size_dto.dart';
import 'package:tryzeon/feature/common/product_size/data/mappers/body_measurement_ranges_mappr.dart';
import 'package:tryzeon/feature/common/product_size/data/mappers/garment_measurements_mappr.dart';
import 'package:tryzeon/feature/common/product_size/data/mappers/product_size_mappr.auto_mappr.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/product_size.dart';

@AutoMappr(
  [
    MapType<ProductSizeDto, ProductSize>(),
    MapType<ProductSize, ProductSizeDto>(),
    MapType<ProductSize, ProductSizeEmbedded>(),
    MapType<ProductSizeEmbedded, ProductSize>(),
  ],
  includes: [GarmentMeasurementsMappr(), BodyMeasurementRangesMappr()],
)
class ProductSizeMappr extends $ProductSizeMappr {
  const ProductSizeMappr();
}
