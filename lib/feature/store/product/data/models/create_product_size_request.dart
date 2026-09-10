import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/product_size/data/models/garment_measurements_model.dart';

part 'create_product_size_request.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class CreateProductSizeRequest {
  const CreateProductSizeRequest({
    required this.productId,
    required this.name,
    this.garmentMeasurements,
  });

  final String productId;
  final String name;
  final GarmentMeasurementsModel? garmentMeasurements;

  Map<String, dynamic> toJson() => _$CreateProductSizeRequestToJson(this);
}
