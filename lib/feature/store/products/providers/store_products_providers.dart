import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/feature/store/products/data/datasources/product_local_datasource.dart';
import 'package:tryzeon/feature/store/products/data/datasources/product_remote_datasource.dart';
import 'package:tryzeon/feature/store/products/data/repositories/product_repository_impl.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/repositories/product_repository.dart';
import 'package:tryzeon/feature/store/products/domain/usecases/create_product.dart';
import 'package:tryzeon/feature/store/products/domain/usecases/delete_product.dart';
import 'package:tryzeon/feature/store/products/domain/usecases/get_products.dart';
import 'package:tryzeon/feature/store/products/domain/usecases/update_product.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_sort_condition.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';
import 'package:typed_result/typed_result.dart';

part 'store_products_providers.g.dart';

@riverpod
ProductRemoteDataSource productRemoteDataSource(final Ref ref) {
  return ProductRemoteDataSource(Supabase.instance.client);
}

@riverpod
ProductLocalDataSource productLocalDataSource(final Ref ref) {
  final isarService = ref.watch(isarServiceProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  return ProductLocalDataSource(isarService, cacheService);
}

@riverpod
ProductRepository productRepository(final Ref ref) {
  return ProductRepositoryImpl(
    remoteDataSource: ref.watch(productRemoteDataSourceProvider),
    localDataSource: ref.watch(productLocalDataSourceProvider),
  );
}

@riverpod
GetProducts getProductsUseCase(final Ref ref) {
  return GetProducts(
    storeProfileRepository: ref.watch(storeProfileRepositoryProvider),
    productRepository: ref.watch(productRepositoryProvider),
  );
}

@riverpod
CreateProduct createProductUseCase(final Ref ref) {
  return CreateProduct(ref.watch(productRepositoryProvider));
}

@riverpod
UpdateProduct updateProductUseCase(final Ref ref) {
  return UpdateProduct(ref.watch(productRepositoryProvider));
}

@riverpod
DeleteProduct deleteProductUseCase(final Ref ref) {
  return DeleteProduct(ref.watch(productRepositoryProvider));
}

/// Provider for product sort condition
@riverpod
class ProductSortCondition extends _$ProductSortCondition {
  @override
  SortCondition build() {
    return SortCondition.defaultSort;
  }

  SortCondition get condition => state;

  set condition(final SortCondition newCondition) {
    state = newCondition;
  }
}

@riverpod
Future<List<Product>> products(final Ref ref) async {
  final sort = ref.watch(productSortConditionProvider);
  final getProductsUseCase = ref.watch(getProductsUseCaseProvider);

  final result = await getProductsUseCase(sort: sort);

  if (result.isFailure) {
    throw result.getError()!;
  }
  return result.get()!;
}

@riverpod
Future<Product> productById(final Ref ref, final String productId) async {
  final repository = ref.watch(productRepositoryProvider);
  final result = await repository.getProductById(productId);

  if (result.isFailure) {
    throw result.getError()!;
  }

  return result.get()!;
}

/// 強制刷新商品列表
/// 注意：此函數會吞掉 refresh 時的異常，確保 ErrorView 的 onRetry 能正常運作
Future<void> refreshProducts(final WidgetRef ref) async {
  final sort = ref.read(productSortConditionProvider);
  final getProductsUseCase = ref.read(getProductsUseCaseProvider);

  await getProductsUseCase(sort: sort, forceRefresh: true);
  try {
    final _ = await ref.refresh(productsProvider.future);
  } catch (_) {
    // Provider 刷新失敗時，忽略異常，讓 UI 顯示 ErrorView 或舊資料
  }
}
