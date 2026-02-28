import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/repositories/product_repository.dart';
import 'package:typed_result/typed_result.dart';

class GetShopProduct {
  const GetShopProduct(this._repository);
  final ProductRepository _repository;

  Future<Result<ShopProduct, Failure>> call(final String productId) {
    return _repository.getProduct(productId);
  }
}
