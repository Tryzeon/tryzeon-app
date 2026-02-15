import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_attributes.dart';

part 'shop_product.freezed.dart';

@freezed
sealed class ShopProduct with _$ShopProduct {
  const factory ShopProduct({
    required final ShopStoreInfo storeInfo,
    required final String name,
    required final Set<String> categories,
    required final double price,
    required final String imagePath,
    required final String imageUrl,
    required final String id,
    final String? purchaseLink,
    final ProductElasticity? elasticity,
    final ProductFit? fit,
    final List<ProductSize>? sizes,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) = _ShopProduct;
}
