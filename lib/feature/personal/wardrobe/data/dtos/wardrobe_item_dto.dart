import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';

part 'wardrobe_item_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class WardrobeItemDto {
  const WardrobeItemDto({
    required this.id,
    required this.imagePath,
    required this.garmentType,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
  });

  factory WardrobeItemDto.fromJson(final Map<String, dynamic> json) =>
      _$WardrobeItemDtoFromJson(json);

  final String id;
  final String imagePath;
  @JsonKey(unknownEnumValue: GarmentType.others)
  final GarmentType garmentType;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
}
