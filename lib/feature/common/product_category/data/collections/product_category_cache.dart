import 'package:isar_community/isar.dart';

part 'product_category_cache.g.dart';

@collection
class ProductCategoryCache {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String categoryId;

  late String name;

  late String code;

  String? gender;

  String? defaultGarmentType;

  String? imageMale;

  String? imageFemale;

  String? imageMaleUrl;

  String? imageFemaleUrl;
}
