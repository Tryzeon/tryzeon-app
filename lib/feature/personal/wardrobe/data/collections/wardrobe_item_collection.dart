import 'package:isar_community/isar.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_category.dart';

part 'wardrobe_item_collection.g.dart';

@collection
class WardrobeItemCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String itemId;

  late String imagePath;

  @Enumerated(EnumType.name)
  late WardrobeCategory category;

  List<String>? tags;

  @Index()
  DateTime? createdAt;

  DateTime? updatedAt;
}
