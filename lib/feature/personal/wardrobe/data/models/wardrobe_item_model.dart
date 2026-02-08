import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/wardrobe_category.dart';
import '../../domain/entities/wardrobe_item.dart';

part 'wardrobe_item_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class WardrobeItemModel {
  const WardrobeItemModel({
    this.id,
    required this.imagePath,
    required this.category,
    this.tags = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory WardrobeItemModel.fromEntity(final WardrobeItem entity) {
    return WardrobeItemModel(
      id: entity.id,
      imagePath: entity.imagePath,
      category: entity.category,
      tags: entity.tags,
    );
  }

  factory WardrobeItemModel.fromJson(final Map<String, dynamic> json) =>
      _$WardrobeItemModelFromJson(json);

  final String? id;
  final String imagePath;
  final WardrobeCategory category;
  final List<String> tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => _$WardrobeItemModelToJson(this);

  WardrobeItem toEntity() {
    return WardrobeItem(id: id, imagePath: imagePath, category: category, tags: tags);
  }
}
