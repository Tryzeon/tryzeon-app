import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/product_size/data/dtos/body_measurement_ranges_dto.dart';
import 'package:tryzeon/feature/common/product_size/data/dtos/garment_measurements_dto.dart';

part 'product_size_dto.g.dart';

/// [explicitToJson] serializes nested garment measurements and body measurement
/// ranges as plain maps, so `jsonDiff` can compare them structurally instead of
/// falling back to identity equality.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class ProductSizeDto {
  const ProductSizeDto({
    required this.id,
    required this.productId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.garmentMeasurements,
    this.bodyMeasurementRanges,
  });

  factory ProductSizeDto.fromJson(final Map<String, dynamic> json) =>
      _$ProductSizeDtoFromJson(json);

  final String id;
  final String productId;
  final String name;
  final GarmentMeasurementsDto? garmentMeasurements;
  final BodyMeasurementRangesDto? bodyMeasurementRanges;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => _$ProductSizeDtoToJson(this);
}
