import 'package:json_annotation/json_annotation.dart';

part 'product_color_dto.g.dart';

/// [toJson] is the update payload, so server-owned columns are left out of it.
@JsonSerializable(fieldRename: FieldRename.snake)
class ProductColorDto {
  const ProductColorDto({
    required this.id,
    required this.productId,
    required this.imagePaths,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
    this.name,
  });

  factory ProductColorDto.fromJson(final Map<String, dynamic> json) =>
      _$ProductColorDtoFromJson(json);

  @JsonKey(includeToJson: false)
  final String id;
  @JsonKey(includeToJson: false)
  final String productId;
  final String? name;
  @JsonKey(defaultValue: <String>[])
  final List<String> imagePaths;
  final int position;
  @JsonKey(includeToJson: false)
  final DateTime createdAt;
  @JsonKey(includeToJson: false)
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => _$ProductColorDtoToJson(this);
}
