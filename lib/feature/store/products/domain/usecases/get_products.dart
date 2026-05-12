import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/repositories/product_repository.dart';
import 'package:typed_result/typed_result.dart';

class GetProducts {
  GetProducts({required final ProductRepository productRepository})
    : _productRepository = productRepository;

  final ProductRepository _productRepository;

  Future<Result<List<Product>, Failure>> call({
    required final String storeId,
    final bool forceRefresh = false,
  }) async {
    return _productRepository.getProducts(storeId: storeId, forceRefresh: forceRefresh);
  }
}
