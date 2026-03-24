import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/image_item.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_attributes.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_sort_condition.dart';
import 'package:typed_result/typed_result.dart';

abstract class ProductRepository {
  Future<Result<List<Product>, Failure>> getProducts({
    required final String storeId,
    final SortCondition sort = SortCondition.defaultSort,
    final bool forceRefresh = false,
  });

  Future<Result<void, Failure>> createProduct(final CreateProductParams params);

  Future<Result<Product, Failure>> getProductById(final String productId);

  Future<Result<void, Failure>> updateProduct({
    required final Product original,
    required final List<ImageItem> finalImageOrder,
    required final List<CreateProductSizeParams> sizesToAdd,
    required final List<ProductSize> sizesToUpdate,
    required final List<String> sizeIdsToDelete,
    required final String name,
    required final List<String> categoryIds,
    required final double price,
    final String? purchaseLink,
    final String? material,
    final ProductElasticity? elasticity,
    final ProductFit? fit,
    final List<ClothingStyle>? styles,
  });

  Future<Result<void, Failure>> deleteProduct(final Product product);
}
