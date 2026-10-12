import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_size_diff.dart';
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
    required final Product target,
    final ProductSizeDiff sizeDiff = const ProductSizeDiff.empty(),
  });

  Future<Result<void, Failure>> deleteProduct({
    required final String storeId,
    required final String productId,
  });
}
