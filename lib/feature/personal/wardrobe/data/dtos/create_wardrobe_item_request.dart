import 'package:json_annotation/json_annotation.dart';

import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';

part 'create_wardrobe_item_request.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class CreateWardrobeItemRequest {
  const CreateWardrobeItemRequest({
    required this.imagePath,
    required this.garmentType,
    this.tags = const [],
  });

  final String imagePath;
  final GarmentType garmentType;
  final List<String> tags;

  Map<String, dynamic> toJson() => _$CreateWardrobeItemRequestToJson(this);
}
