import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/product_size/data/models/body_measurement_ranges_model.dart';
import 'package:tryzeon/feature/common/product_size/data/models/garment_measurements_model.dart';

part 'create_product_size_request.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class CreateProductSizeRequest {
  const CreateProductSizeRequest({
    required this.productId,
    required this.name,
    this.garmentMeasurements,
    this.bodyMeasurementRanges,
  });

  final String productId;
  final String name;
  final GarmentMeasurementsModel? garmentMeasurements;
  final BodyMeasurementRangesModel? bodyMeasurementRanges;

  Map<String, dynamic> toJson() => _$CreateProductSizeRequestToJson(this);
}
