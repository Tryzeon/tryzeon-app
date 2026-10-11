import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_filter.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/repositories/product_repository.dart';
import 'package:typed_result/typed_result.dart';

part 'list_shop_products.freezed.dart';

@freezed
sealed class ListShopProductsParams with _$ListShopProductsParams {
  const factory ListShopProductsParams({
    required final ShopFilter filter,
    required final int limit,
    required final int offset,
  }) = _ListShopProductsParams;
}

class ListShopProducts {
  ListShopProducts(this._repository);

  final ProductRepository _repository;

  Future<Result<List<ShopProduct>, Failure>> call(
    final ListShopProductsParams params,
  ) {
    return _repository.listProducts(
      params.filter,
      limit: params.limit,
      offset: params.offset,
    );
  }
}
