import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/presentation/state/pull_to_refresh.dart';
import 'package:tryzeon/feature/personal/shop/data/datasources/ad_local_datasource.dart';
import 'package:tryzeon/feature/personal/shop/data/datasources/shop_remote_datasource.dart';
import 'package:tryzeon/feature/personal/shop/data/repositories/ad_repository_impl.dart';
import 'package:tryzeon/feature/personal/shop/data/repositories/product_repository_impl.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:tryzeon/feature/personal/shop/domain/repositories/ad_repository.dart';
import 'package:tryzeon/feature/personal/shop/domain/repositories/product_repository.dart';
import 'package:tryzeon/feature/personal/shop/domain/usecases/get_ads.dart';
import 'package:tryzeon/feature/personal/shop/domain/usecases/get_shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/usecases/get_store_info.dart';
import 'package:tryzeon/feature/personal/shop/domain/usecases/list_shop_products.dart';
import 'package:tryzeon/feature/personal/shop/domain/usecases/track_product_purchase_click.dart';
import 'package:tryzeon/feature/personal/shop/domain/usecases/track_product_view.dart';
import 'package:typed_result/typed_result.dart';

part 'shop_providers.g.dart';

// --- Data Sources ---

@riverpod
ShopRemoteDataSource shopRemoteDataSource(final Ref ref) {
  return ShopRemoteDataSource(Supabase.instance.client);
}

@riverpod
AdLocalDataSource adLocalDataSource(final Ref ref) {
  return AdLocalDataSource();
}

// --- Repositories ---

@riverpod
ProductRepository productRepository(final Ref ref) {
  final remote = ref.watch(shopRemoteDataSourceProvider);
  return ProductRepositoryImpl(remoteDataSource: remote);
}

@riverpod
AdRepository adRepository(final Ref ref) {
  final adLocal = ref.watch(adLocalDataSourceProvider);
  return AdRepositoryImpl(adLocal);
}

// --- Use Cases ---

@riverpod
ListShopProducts listShopProducts(final Ref ref) {
  return ListShopProducts(ref.watch(productRepositoryProvider));
}

@riverpod
GetShopProduct getShopProduct(final Ref ref) {
  return GetShopProduct(ref.watch(productRepositoryProvider));
}

@riverpod
GetStoreInfo getStoreInfo(final Ref ref) {
  return GetStoreInfo(ref.watch(productRepositoryProvider));
}

@riverpod
GetAds getAds(final Ref ref) {
  return GetAds(ref.watch(adRepositoryProvider));
}

@riverpod
TrackProductView trackProductView(final Ref ref) {
  return TrackProductView(ref.watch(analyticsEventQueueProvider));
}

@riverpod
TrackProductPurchaseClick trackProductPurchaseClick(final Ref ref) {
  return TrackProductPurchaseClick(ref.watch(analyticsEventQueueProvider));
}

// --- Feature Providers ---

@riverpod
Future<ShopProduct> shopProductById(
  final Ref ref,
  final String productId,
) async {
  final getUseCase = ref.watch(getShopProductProvider);
  final result = await getUseCase(productId);
  if (result.isFailure) {
    throw result.getError()!;
  }
  return result.get()!;
}

@riverpod
Future<List<String>> shopAds(final Ref ref) async {
  final getAdsUseCase = ref.watch(getAdsProvider);
  final result = await getAdsUseCase();
  if (result.isFailure) {
    throw result.getError()!;
  }
  return result.get()!;
}

@riverpod
class StoreInfoNotifier extends _$StoreInfoNotifier
    with PullToRefresh<ShopStoreInfo> {
  @override
  Future<ShopStoreInfo> build(final String storeId) async {
    final result = await ref.watch(getStoreInfoProvider)(storeId);
    if (result.isFailure) {
      throw result.getError()!;
    }
    return result.get()!;
  }

  Future<Result<void, Failure>> refresh() =>
      applyRefresh(() => ref.read(getStoreInfoProvider)(storeId));
}
