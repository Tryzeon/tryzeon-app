import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:tryzeon/feature/personal/shop/domain/repositories/product_repository.dart';
import 'package:typed_result/typed_result.dart';

class GetStoreInfo {
  const GetStoreInfo(this._repository);
  final ProductRepository _repository;

  Future<Result<ShopStoreInfo, Failure>> call(final String storeId) {
    return _repository.getStoreInfo(storeId);
  }
}
