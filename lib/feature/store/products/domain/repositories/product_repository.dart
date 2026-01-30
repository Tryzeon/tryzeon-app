import 'dart:io';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_sort_condition.dart';
import 'package:typed_result/typed_result.dart';

abstract class ProductRepository {
  Future<Result<List<Product>, Failure>> getProducts({
    required final String storeId,
    final SortCondition sort = SortCondition.defaultSort,
    final bool forceRefresh = false,
  });

  Future<Result<void, Failure>> createProduct({
    required final Product product,
    required final File image,
  });

  Future<Result<void, Failure>> updateProduct({
    required final Product original,
    required final Product target,
    final File? newImage,
  });

  Future<Result<void, Failure>> deleteProduct(final Product product);
}
