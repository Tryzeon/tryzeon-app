import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_color_diff.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_size_diff.dart';
import 'package:typed_result/typed_result.dart';

abstract class ProductRepository {
  Future<Result<List<Product>, Failure>> listProducts({
    required final String storeId,
    final bool forceRefresh = false,
  });

  /// The written product is null when the write landed but reading it back
  /// failed.
  Future<Result<Product?, Failure>> createProduct(final NewProduct product);

  /// The written product is null when the write landed but reading it back
  /// failed.
  Future<Result<Product?, Failure>> updateProduct({
    required final Product original,
    required final Product target,
    final ProductSizeDiff sizeDiff = const ProductSizeDiff.empty(),
    final ProductColorDiff colorDiff = const ProductColorDiff.empty(),
  });

  Future<Result<void, Failure>> deleteProduct({
    required final String storeId,
    required final String productId,
  });
}
