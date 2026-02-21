import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_attributes.dart';

part 'create_product_request.g.dart';

/// Client → Server：建立商品時使用
/// 不含 id, imageUrl, sizes, createdAt, updatedAt（皆由 server 產生或另外處理）
@JsonSerializable(fieldRename: FieldRename.snake)
class CreateProductRequest {
  const CreateProductRequest({
    required this.storeId,
    required this.name,
    required this.categories,
    required this.price,
    required this.imagePath,
    this.purchaseLink,
    this.material,
    this.elasticity,
    this.fit,
  });

  final String storeId;
  final String name;
  final Set<String> categories;
  final double price;
  final String imagePath;
  final String? purchaseLink;
  final String? material;
  final ProductElasticity? elasticity;
  final ProductFit? fit;

  Map<String, dynamic> toJson() => _$CreateProductRequestToJson(this);
}
