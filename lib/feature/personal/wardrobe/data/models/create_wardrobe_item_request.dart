import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/wardrobe_category.dart';

part 'create_wardrobe_item_request.g.dart';

/// Client → Server：建立衣櫃項目時使用，不含 id/createdAt/updatedAt
@JsonSerializable(fieldRename: FieldRename.snake)
class CreateWardrobeItemRequest {
  const CreateWardrobeItemRequest({
    required this.imagePath,
    required this.category,
    this.tags = const [],
  });

  final String imagePath;
  final WardrobeCategory category;
  final List<String> tags;

  Map<String, dynamic> toJson() => _$CreateWardrobeItemRequestToJson(this);
}
