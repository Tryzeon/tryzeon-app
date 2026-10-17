import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/domain/repositories/product_repository.dart';
import 'package:typed_result/typed_result.dart';

part 'set_product_status.freezed.dart';

@freezed
sealed class SetProductStatusParams with _$SetProductStatusParams {
  const factory SetProductStatusParams({
    required final Product product,
    required final ProductStatus status,
  }) = _SetProductStatusParams;
}

class SetProductStatus {
  SetProductStatus(this._repository);
  final ProductRepository _repository;

  Future<Result<Product?, Failure>> call(
    final SetProductStatusParams params,
  ) async {
    final original = params.product;
    final target = original.copyWith(status: params.status);
    if (target == original) return Ok(original);

    return _repository.updateProduct(original: original, target: target);
  }
}
