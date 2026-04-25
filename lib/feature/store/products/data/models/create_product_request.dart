import 'package:json_annotation/json_annotation.dart';

part 'create_product_request.g.dart';

/// Client → Server：建立商品時使用
/// 不含 id, imageUrl, sizes, createdAt, updatedAt（皆由 server 產生或另外處理）
@JsonSerializable(fieldRename: FieldRename.snake)
class CreateProductRequest {
  const CreateProductRequest({
    required this.storeId,
    required this.name,
    required this.categoryIds,
    required this.price,
    required this.imagePaths,
    this.purchaseLink,
    this.material,
    this.elasticity,
    this.fit,
    this.thickness,
    this.styles,
    this.seasons,
  });

  final String storeId;
  final String name;
  final List<String> categoryIds;
  final double price;
  final List<String> imagePaths;
  final String? purchaseLink;
  final String? material;
  final String? elasticity;
  final String? fit;
  final String? thickness;
  final List<String>? styles;
  final List<String>? seasons;

  Map<String, dynamic> toJson() => _$CreateProductRequestToJson(this);
}
