import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/product_size/data/dtos/body_measurement_ranges_dto.dart';
import 'package:tryzeon/feature/common/product_size/data/dtos/garment_measurements_dto.dart';

part 'product_size_draft_dto.g.dart';

@JsonSerializable(
  fieldRename: FieldRename.snake,
  createFactory: false,
  explicitToJson: true,
)
class ProductSizeDraftDto {
  const ProductSizeDraftDto({
    required this.name,
    this.garmentMeasurements,
    this.bodyMeasurementRanges,
  });

  final String name;
  final GarmentMeasurementsDto? garmentMeasurements;
  final BodyMeasurementRangesDto? bodyMeasurementRanges;

  Map<String, dynamic> toJson() => _$ProductSizeDraftDtoToJson(this);
}
