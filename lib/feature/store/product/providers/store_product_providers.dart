import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/core/error/failure_from_error.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/presentation/state/apply_write.dart';
import 'package:tryzeon/core/presentation/state/pull_to_refresh.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_category/providers/product_category_providers.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/product_analytics_summary.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';
import 'package:tryzeon/feature/store/product/data/datasources/product_local_datasource.dart';
import 'package:tryzeon/feature/store/product/data/datasources/product_remote_datasource.dart';
import 'package:tryzeon/feature/store/product/data/repositories/product_repository_impl.dart';
import 'package:tryzeon/feature/store/product/data/services/audio_recorder_service_impl.dart';
import 'package:tryzeon/feature/store/product/data/services/product_image_analyzer_impl.dart';
import 'package:tryzeon/feature/store/product/data/services/product_image_storage_impl.dart';
import 'package:tryzeon/feature/store/product/data/services/size_voice_parser_impl.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product_image_analysis.dart';
import 'package:tryzeon/feature/store/product/domain/repositories/product_repository.dart';
import 'package:tryzeon/feature/store/product/domain/services/audio_recorder_service.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_image_analyzer.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_image_storage.dart';
import 'package:tryzeon/feature/store/product/domain/services/size_voice_parser.dart';
import 'package:tryzeon/feature/store/product/domain/usecases/analyze_product_image.dart';
import 'package:tryzeon/feature/store/product/domain/usecases/create_product.dart';
import 'package:tryzeon/feature/store/product/domain/usecases/delete_product.dart';
import 'package:tryzeon/feature/store/product/domain/usecases/list_products.dart';
import 'package:tryzeon/feature/store/product/domain/usecases/parse_size_voice.dart';
import 'package:tryzeon/feature/store/product/domain/usecases/set_product_status.dart';
import 'package:tryzeon/feature/store/product/domain/usecases/update_product.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/image_item.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/size_item.dart';
import 'package:tryzeon/feature/store/product/presentation/state/product_query_state.dart';
import 'package:tryzeon/feature/store/product/presentation/state/product_sort_condition.dart';
import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';
import 'package:tryzeon/feature/store/providers/store_providers.dart';
import 'package:typed_result/typed_result.dart';

part 'store_product_providers.g.dart';

@riverpod
ProductRemoteDataSource productRemoteDataSource(final Ref ref) {
  return ProductRemoteDataSource(ref.watch(supabaseClientProvider));
}

@riverpod
ProductImageStorage productImageStorage(final Ref ref) {
  return ProductImageStorageImpl(ref.watch(storeImagesApiProvider));
}

@riverpod
ProductLocalDataSource productLocalDataSource(final Ref ref) {
  final isarService = ref.watch(isarServiceProvider);
  final cacheEntryLocalDataSource = ref.watch(
    cacheEntryLocalDataSourceProvider,
  );
  return ProductLocalDataSource(isarService, cacheEntryLocalDataSource);
}

@riverpod
ProductRepository productRepository(final Ref ref) {
  return ProductRepositoryImpl(
    remoteDataSource: ref.watch(productRemoteDataSourceProvider),
    localDataSource: ref.watch(productLocalDataSourceProvider),
  );
}

@riverpod
ListProducts listProductsUseCase(final Ref ref) {
  return ListProducts(productRepository: ref.watch(productRepositoryProvider));
}

@riverpod
CreateProduct createProductUseCase(final Ref ref) {
  return CreateProduct(
    repository: ref.watch(productRepositoryProvider),
    imageStorage: ref.watch(productImageStorageProvider),
  );
}

@riverpod
UpdateProduct updateProductUseCase(final Ref ref) {
  return UpdateProduct(
    repository: ref.watch(productRepositoryProvider),
    imageStorage: ref.watch(productImageStorageProvider),
  );
}

@riverpod
SetProductStatus setProductStatusUseCase(final Ref ref) {
  return SetProductStatus(ref.watch(productRepositoryProvider));
}

@riverpod
DeleteProduct deleteProductUseCase(final Ref ref) {
  return DeleteProduct(
    repository: ref.watch(productRepositoryProvider),
    imageStorage: ref.watch(productImageStorageProvider),
  );
}

@Riverpod(keepAlive: true)
class ProductQuery extends _$ProductQuery {
  @override
  ProductQueryState build() => const ProductQueryState();

  void updateSearch(final String query) {
    state = state.copyWith(searchQuery: query);
  }

  void updateSort(final SortCondition sort) {
    state = state.copyWith(sort: sort);
  }

  void updateStatus(final ProductStatus status) {
    state = state.copyWith(status: status);
  }
}

@riverpod
class ProductsNotifier extends _$ProductsNotifier
    with PullToRefresh<List<Product>>, ApplyWrite<List<Product>> {
  static const _missingProfile = UnknownFailure('Store profile not found');

  @override
  Future<List<Product>> build() async {
    final storeId = await ref.watch(
      storeProfileProvider.selectAsync((final profile) => profile?.id),
    );
    if (storeId == null || storeId.isEmpty) {
      throw _missingProfile;
    }

    final listProductsUseCase = ref.watch(listProductsUseCaseProvider);
    final result = await listProductsUseCase(storeId: storeId);

    if (result.isFailure) {
      throw result.getError()!;
    }
    return result.get()!;
  }

  Future<Result<void, Failure>> refresh() {
    if (ref.read(storeProfileProvider).hasError) {
      ref.invalidate(storeProfileProvider);
    }
    return applyRefresh(() async {
      final StoreProfile? profile;
      try {
        profile = await ref.read(storeProfileProvider.future);
      } on Failure catch (e) {
        return Err(e);
      }
      if (profile == null || profile.id.isEmpty) {
        return const Err(_missingProfile);
      }
      return ref.read(listProductsUseCaseProvider)(
        storeId: profile.id,
        forceRefresh: true,
      );
    });
  }

  Future<Result<Product?, Failure>> createProduct({
    required final ProductDraft draft,
    required final List<File> images,
    required final List<NewSizeItem> sizes,
  }) => applyWrite(
    () async {
      final StoreProfile? storeProfile;
      try {
        storeProfile = await ref.read(storeProfileProvider.future);
      } on Failure catch (e) {
        return Err(e);
      }
      if (storeProfile == null) {
        return const Err(AuthFailure('無法獲取店家資訊，請重新登入'));
      }
      return ref.read(createProductUseCaseProvider)(
        CreateProductParams(
          storeId: storeProfile.id,
          draft: draft,
          images: images,
          sizes: sizes,
        ),
      );
    },
    merge: (final products, final created) =>
        created == null ? null : [created, ...products],
  );

  /// The original the draft is diffed against is read here rather than taken
  /// from the form, so a stale form can't clobber server-owned fields.
  Future<Result<Product?, Failure>> updateProduct({
    required final String productId,
    required final ProductDraft draft,
    required final List<ImageItem> images,
    required final List<SizeItem> sizes,
  }) => applyWrite(() async {
    final List<Product> products;
    try {
      products = await future;
    } on Failure catch (e) {
      return Err(e);
    }
    final original = products.where((final p) => p.id == productId).firstOrNull;
    if (original == null) return const Err(NotFoundFailure());
    return ref.read(updateProductUseCaseProvider)(
      UpdateProductParams(
        original: original,
        draft: draft,
        images: images,
        sizes: sizes,
      ),
    );
  }, merge: _replace);

  Future<Result<Product?, Failure>> setProductStatus({
    required final Product product,
    required final ProductStatus status,
  }) => applyWrite(
    () => ref.read(setProductStatusUseCaseProvider)(
      SetProductStatusParams(product: product, status: status),
    ),
    merge: _replace,
  );

  Future<Result<void, Failure>> deleteProduct(final Product target) =>
      applyWrite(
        () => ref.read(deleteProductUseCaseProvider)(target),
        merge: (final products, final _) => [
          for (final product in products)
            if (product.id != target.id) product,
        ],
      );

  static List<Product>? _replace(
    final List<Product> products,
    final Product? updated,
  ) => updated == null
      ? null
      : [
          for (final product in products)
            product.id == updated.id ? updated : product,
        ];
}

@riverpod
Future<List<Product>> filteredProducts(final Ref ref) async {
  final products = await ref.watch(productsProvider.future);
  final query = ref.watch(productQueryProvider);

  final analyticsAsync = ref.watch(productAnalyticsSummariesProvider);
  final summaries = analyticsAsync.when(
    data: (final v) => v,
    loading: () => const <ProductAnalyticsSummary>[],
    error: (final e, final st) {
      AppLogger.warning('Analytics summaries unavailable for sort', e, st);
      return const <ProductAnalyticsSummary>[];
    },
  );
  final byId = {for (final s in summaries) s.productId: s};

  int lookup(final String productId, final AnalyticsMetric metric) {
    final summary = byId[productId];
    return summary == null ? 0 : metric.countIn(summary);
  }

  return filterAndSortProducts(products, query, lookup);
}

@riverpod
Future<Product> productById(final Ref ref, final String productId) async {
  final product = await ref.watch(
    productsProvider.selectAsync(
      (final products) =>
          products.where((final p) => p.id == productId).firstOrNull,
    ),
  );
  if (product == null) throw const NotFoundFailure();
  return product;
}

@riverpod
ProductImageAnalyzer productImageAnalyzer(final Ref ref) =>
    ProductImageAnalyzerImpl(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
AnalyzeProductImage analyzeProductImageUseCase(final Ref ref) =>
    AnalyzeProductImage(
      ref.watch(productImageAnalyzerProvider),
      ref.watch(productCategoryRepositoryProvider),
    );

@riverpod
Future<ProductImageAnalysis> productImageAnalysis(
  final Ref ref,
  final String imagePath,
) async {
  final result = await ref.watch(analyzeProductImageUseCaseProvider)(
    File(imagePath),
  );
  if (result.isFailure) throw result.getError()!;
  return result.get()!;
}

@riverpod
SizeVoiceParser sizeVoiceParser(final Ref ref) =>
    SizeVoiceParserImpl(ref.watch(supabaseClientProvider));

@riverpod
ParseSizeVoice parseSizeVoiceUseCase(final Ref ref) =>
    ParseSizeVoice(ref.watch(sizeVoiceParserProvider));

@Riverpod(keepAlive: true)
AudioRecorderService audioRecorderService(final Ref ref) =>
    AudioRecorderServiceImpl();

enum ProductMutation { create, update, setStatus, delete }

@riverpod
class ProductEditNotifier extends _$ProductEditNotifier {
  @override
  ProductMutation? build() => null;

  Future<Result<void, Failure>> create({
    required final ProductDraft draft,
    required final List<File> images,
    required final List<NewSizeItem> sizes,
  }) => _write(
    ProductMutation.create,
    () => _products.createProduct(draft: draft, images: images, sizes: sizes),
  );

  Future<Result<void, Failure>> update({
    required final String productId,
    required final ProductDraft draft,
    required final List<ImageItem> images,
    required final List<SizeItem> sizes,
  }) => _write(
    ProductMutation.update,
    () => _products.updateProduct(
      productId: productId,
      draft: draft,
      images: images,
      sizes: sizes,
    ),
  );

  Future<Result<void, Failure>> setStatus({
    required final Product product,
    required final ProductStatus status,
  }) => _write(
    ProductMutation.setStatus,
    () => _products.setProductStatus(product: product, status: status),
  );

  Future<Result<void, Failure>> delete(final Product product) =>
      _write(ProductMutation.delete, () => _products.deleteProduct(product));

  ProductsNotifier get _products => ref.read(productsProvider.notifier);

  /// Kept alive for the duration, so a form popped mid-write doesn't dispose
  /// this notifier out from under the pending `state` write.
  Future<Result<void, Failure>> _write(
    final ProductMutation mutation,
    final Future<Result<Object?, Failure>> Function() write,
  ) async {
    final link = ref.keepAlive();
    state = mutation;
    try {
      return (await write()).map((final _) {});
    } catch (e, stackTrace) {
      AppLogger.error('Product $mutation failed', e, stackTrace);
      return Err(failureFromError(e));
    } finally {
      state = null;
      link.close();
    }
  }
}
