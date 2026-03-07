import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/personal/shop/data/models/shop_store_info_model.dart';
import 'package:tryzeon/feature/store/products/data/models/product_model.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_attributes.dart';

part 'shop_product_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ShopProductModel {
  const ShopProductModel({
    required this.storeInfo,
    required this.name,
    required this.categoryId,
    required this.price,
    required this.imagePath,
    required this.imageUrl,
    required this.id,
    this.purchaseLink,
    this.material,
    this.elasticity,
    this.fit,
    this.sizes,
    this.createdAt,
    this.updatedAt,
  });

  factory ShopProductModel.fromJson(final Map<String, dynamic> json) =>
      _$ShopProductModelFromJson(json);

  @JsonKey(name: 'store_profiles', includeToJson: false)
  final ShopStoreInfoModel storeInfo;
  final String name;
  final String categoryId;
  final double price;
  final String imagePath;
  @JsonKey(includeToJson: false)
  final String imageUrl;
  final String id;
  final String? purchaseLink;
  final String? material;
  final ProductElasticity? elasticity;
  final ProductFit? fit;
  @JsonKey(name: 'product_variants', includeToJson: false)
  final List<ProductSizeModel>? sizes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => _$ShopProductModelToJson(this);
}
