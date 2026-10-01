import 'package:json_annotation/json_annotation.dart';

import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';

part 'update_wardrobe_item_request.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class UpdateWardrobeItemRequest {
  const UpdateWardrobeItemRequest({this.garmentType, this.tags});

  final GarmentType? garmentType;
  final List<String>? tags;

  Map<String, dynamic> toJson() => _$UpdateWardrobeItemRequestToJson(this);
}
