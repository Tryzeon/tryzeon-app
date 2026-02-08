import '../../domain/entities/wardrobe_category.dart';
import '../collections/wardrobe_item_collection.dart';
import '../models/wardrobe_item_model.dart';

extension WardrobeItemModelMapper on WardrobeItemModel {
  WardrobeItemCollection toCollection() {
    return WardrobeItemCollection()
      ..itemId = id ?? ''
      ..imagePath = imagePath
      ..category = category.name
      ..tags = tags
      ..createdAt = createdAt
      ..updatedAt = updatedAt;
  }
}

extension WardrobeItemCollectionMapper on WardrobeItemCollection {
  WardrobeItemModel toModel() {
    return WardrobeItemModel(
      id: itemId,
      imagePath: imagePath,
      category: WardrobeCategory.fromApiString(category),
      tags: tags ?? [],
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
