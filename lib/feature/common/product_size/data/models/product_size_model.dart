import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/product_size/data/models/body_measurement_ranges_model.dart';
import 'package:tryzeon/feature/common/product_size/data/models/garment_measurements_model.dart';

part 'product_size_model.g.dart';

/// [explicitToJson] serializes nested garment measurements and body measurement
/// ranges as plain maps, so `jsonDiff` can compare them structurally instead of
/// falling back to identity equality.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class ProductSizeModel {
  const ProductSizeModel({
    required this.id,
    required this.productId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.garmentMeasurements,
    this.bodyMeasurementRanges,
  });

  factory ProductSizeModel.fromJson(final Map<String, dynamic> json) =>
      _$ProductSizeModelFromJson(json);

  final String id;
  final String productId;
  final String name;
  final GarmentMeasurementsModel? garmentMeasurements;
  final BodyMeasurementRangesModel? bodyMeasurementRanges;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => _$ProductSizeModelToJson(this);
}
