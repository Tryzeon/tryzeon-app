import 'package:json_annotation/json_annotation.dart';

part 'create_product_request.g.dart';

/// Client → Server：建立商品時使用
/// 不含 id, imageUrl, sizes, createdAt, updatedAt（皆由 server 產生或另外處理）
@JsonSerializable(fieldRename: FieldRename.snake)
class CreateProductRequest {
  const CreateProductRequest({
    required this.storeId,
    required this.name,
    required this.categoryId,
    required this.price,
    required this.imagePath,
    this.purchaseLink,
    this.material,
    this.elasticity,
    this.fit,
    this.styles,
  });

  final String storeId;
  final String name;
  final String categoryId;
  final double price;
  final String imagePath;
  final String? purchaseLink;
  final String? material;
  final String? elasticity;
  final String? fit;
  final List<String>? styles;

  Map<String, dynamic> toJson() => _$CreateProductRequestToJson(this);
}
