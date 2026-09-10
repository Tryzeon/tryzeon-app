import 'package:isar_community/isar.dart';
import 'package:tryzeon/feature/common/product_size/data/collections/body_measurement_ranges_embedded.dart';
import 'package:tryzeon/feature/common/product_size/data/collections/garment_measurements_embedded.dart';

part 'product_size_embedded.g.dart';

@embedded
class ProductSizeEmbedded {
  late String id;
  late String productId;
  late String name;

  GarmentMeasurementsEmbedded? garmentMeasurements;
  BodyMeasurementRangesEmbedded? bodyMeasurementRanges;
  late DateTime createdAt;
  late DateTime updatedAt;
}
