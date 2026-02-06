import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/feature/common/product_categories/data/datasources/product_category_local_datasource.dart';
import 'package:tryzeon/feature/common/product_categories/data/datasources/product_category_remote_datasource.dart';
import 'package:tryzeon/feature/common/product_categories/data/repositories/product_category_repository_impl.dart';
import 'package:tryzeon/feature/common/product_categories/domain/repositories/product_category_repository.dart';
import 'package:tryzeon/feature/common/product_categories/domain/usecases/get_product_categories.dart';
import 'package:typed_result/typed_result.dart';

part 'product_categories_providers.g.dart';

// Data Sources
@riverpod
ProductCategoryRemoteDataSource productCategoryRemoteDataSource(final Ref ref) {
  return ProductCategoryRemoteDataSource(Supabase.instance.client);
}

@riverpod
ProductCategoryLocalDataSource productCategoryLocalDataSource(final Ref ref) {
  final isarService = ref.watch(isarServiceProvider);
  return ProductCategoryLocalDataSource(isarService);
}

// Repository
@riverpod
ProductCategoryRepository productCategoryRepository(final Ref ref) {
  return ProductCategoryRepositoryImpl(
    ref.watch(productCategoryRemoteDataSourceProvider),
    ref.watch(productCategoryLocalDataSourceProvider),
  );
}

// Use Cases
@riverpod
GetProductCategories getProductCategoriesUseCase(final Ref ref) {
  return GetProductCategories(ref.watch(productCategoryRepositoryProvider));
}

// Providers
@riverpod
Future<List<String>> productCategories(final Ref ref) async {
  final result = await ref.watch(getProductCategoriesUseCaseProvider).call();

  if (result.isSuccess) {
    return result.get()!.map((final e) => e.name).toList();
  } else {
    throw result.getError()!;
  }
}
