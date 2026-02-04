import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/shop/domain/repositories/shop_repository.dart';
import 'package:typed_result/typed_result.dart';

class IncrementTryonCount {
  IncrementTryonCount(this._repository);
  final ShopRepository _repository;

  Future<Result<void, Failure>> call({
    required final String productId,
    required final String storeId,
  }) {
    return _repository.incrementTryonCount(productId: productId, storeId: storeId);
  }
}
