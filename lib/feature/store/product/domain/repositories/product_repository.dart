import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_update_plan.dart';
import 'package:typed_result/typed_result.dart';

abstract class ProductRepository {
  Future<Result<List<Product>, Failure>> listProducts({
    required final String storeId,
    final bool forceRefresh = false,
  });

  Future<Result<void, Failure>> createProduct(final NewProduct product);

  Future<Result<Product, Failure>> getProductById(final String productId);

  Future<Result<void, Failure>> updateProduct({
    required final Product original,
    required final ProductUpdatePlan plan,
  });

  Future<Result<void, Failure>> setProductStatus({
    required final Product product,
    required final ProductStatus status,
  });

  Future<Result<void, Failure>> deleteProduct({
    required final String storeId,
    required final String productId,
  });
}
