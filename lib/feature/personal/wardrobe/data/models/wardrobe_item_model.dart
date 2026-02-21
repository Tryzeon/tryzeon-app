import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/wardrobe_category.dart';

part 'wardrobe_item_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class WardrobeItemModel {
  const WardrobeItemModel({
    required this.id,
    required this.imagePath,
    required this.category,
    this.createdAt,
    this.updatedAt,
    this.tags = const [],
  });

  factory WardrobeItemModel.fromJson(final Map<String, dynamic> json) =>
      _$WardrobeItemModelFromJson(json);

  final String id;
  final String imagePath;
  final WardrobeCategory category;
  final List<String> tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => _$WardrobeItemModelToJson(this);
}

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
