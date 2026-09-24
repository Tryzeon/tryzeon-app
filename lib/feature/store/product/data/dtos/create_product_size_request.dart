import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/product_size/data/dtos/body_measurement_ranges_dto.dart';
import 'package:tryzeon/feature/common/product_size/data/dtos/garment_measurements_dto.dart';

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
  final GarmentMeasurementsDto? garmentMeasurements;
  final BodyMeasurementRangesDto? bodyMeasurementRanges;

  Map<String, dynamic> toJson() => _$CreateProductSizeRequestToJson(this);
}
