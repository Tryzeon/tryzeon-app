import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/core/shared/measurements/data/models/measurements_model.dart';

part 'product_size_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ProductSizeModel {
  const ProductSizeModel({
    required this.id,
    required this.productId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.measurements,
  });

  factory ProductSizeModel.fromJson(final Map<String, dynamic> json) =>
      _$ProductSizeModelFromJson(json);

  final String id;
  final String productId;
  final String name;
  final MeasurementsModel? measurements;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => _$ProductSizeModelToJson(this);
}
