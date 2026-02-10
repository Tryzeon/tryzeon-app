import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/product_categories/domain/entities/product_category.dart';

part 'product_category_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ProductCategoryModel {
  const ProductCategoryModel({
    required this.id,
    required this.name,
    this.parentId,
    this.imagePath,
  });

  factory ProductCategoryModel.fromJson(final Map<String, dynamic> json) =>
      _$ProductCategoryModelFromJson(json);

  final String id;
  final String name;
  final String? parentId;
  final String? imagePath;

  Map<String, dynamic> toJson() => _$ProductCategoryModelToJson(this);

  ProductCategory toEntity() {
    return ProductCategory(id: id, name: name, parentId: parentId, imagePath: imagePath);
  }
}
