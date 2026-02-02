import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/repositories/product_repository.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_sort_condition.dart';
import 'package:tryzeon/feature/store/profile/domain/repositories/store_profile_repository.dart';
import 'package:typed_result/typed_result.dart';

class GetProducts {
  GetProducts({
    required final StoreProfileRepository storeProfileRepository,
    required final ProductRepository productRepository,
  }) : _storeProfileRepository = storeProfileRepository,
       _productRepository = productRepository;

  final StoreProfileRepository _storeProfileRepository;
  final ProductRepository _productRepository;

  Future<Result<List<Product>, Failure>> call({
    required final SortCondition sort,
    final bool forceRefresh = false,
  }) async {
    // 1. Get store profile to extract storeId
    final storeProfileResult = await _storeProfileRepository.getStoreProfile(
      forceRefresh: forceRefresh,
    );

    if (storeProfileResult.isFailure) {
      return Err(storeProfileResult.getError()!);
    }

    final storeProfile = storeProfileResult.get();

    // 2. Validate store profile exists
    if (storeProfile == null || storeProfile.id.isEmpty) {
      return const Err(UnknownFailure('找不到店家資料，請先完成店家設定'));
    }

    // 3. Fetch products using storeId
    return _productRepository.getProducts(
      storeId: storeProfile.id,
      sort: sort,
      forceRefresh: forceRefresh,
    );
  }
}
