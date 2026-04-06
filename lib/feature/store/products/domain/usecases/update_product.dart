import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/repositories/product_repository.dart';
import 'package:typed_result/typed_result.dart';

class UpdateProduct {
  UpdateProduct(this._repository);
  final ProductRepository _repository;

  Future<Result<void, Failure>> call({
    required final Product original,
    required final UpdateProductParams params,
  }) {
    return _repository.updateProduct(original: original, params: params);
  }
}
