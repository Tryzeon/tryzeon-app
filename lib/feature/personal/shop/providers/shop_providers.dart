import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/core/modules/location/domain/entities/user_location.dart';
import 'package:tryzeon/feature/common/product_categories/providers/product_categories_providers.dart';
import 'package:tryzeon/feature/personal/settings/providers/settings_providers.dart';
import 'package:tryzeon/feature/personal/shop/data/datasources/ad_local_datasource.dart';
import 'package:tryzeon/feature/personal/shop/data/datasources/shop_remote_datasource.dart';
import 'package:tryzeon/feature/personal/shop/data/repositories/shop_repository_impl.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_filter.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/repositories/shop_repository.dart';
import 'package:tryzeon/feature/personal/shop/domain/usecases/get_ads.dart';
import 'package:tryzeon/feature/personal/shop/domain/usecases/get_shop_products.dart';
import 'package:tryzeon/feature/personal/shop/domain/usecases/increment_purchase_click_count.dart';
import 'package:tryzeon/feature/personal/shop/domain/usecases/increment_tryon_count.dart';
import 'package:tryzeon/feature/personal/shop/domain/usecases/increment_view_count.dart';
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

// --- Repository ---

@riverpod
ShopRepository shopRepository(final Ref ref) {
  final remote = ref.watch(shopRemoteDataSourceProvider);
  final adLocal = ref.watch(adLocalDataSourceProvider);
  final analyticsQueue = ref.watch(analyticsEventQueueServiceProvider);
  return ShopRepositoryImpl(remote, adLocal, analyticsQueue);
}

// --- Use Cases ---

@riverpod
GetShopProducts getShopProducts(final Ref ref) {
  return GetShopProducts(ref.watch(shopRepositoryProvider));
}

@riverpod
GetAds getAds(final Ref ref) {
  return GetAds(ref.watch(shopRepositoryProvider));
}

@riverpod
IncrementTryonCount incrementTryonCount(final Ref ref) {
  return IncrementTryonCount(ref.watch(shopRepositoryProvider));
}

@riverpod
IncrementViewCount incrementViewCount(final Ref ref) {
  return IncrementViewCount(ref.watch(shopRepositoryProvider));
}

@riverpod
IncrementPurchaseClickCount incrementPurchaseClickCount(final Ref ref) {
  return IncrementPurchaseClickCount(ref.watch(shopRepositoryProvider));
}

// --- Feature Providers ---

@riverpod
Future<List<ShopProduct>> shopProducts(final Ref ref, final ShopFilter filter) async {
  final getShopProductsUseCase = ref.watch(getShopProductsProvider);
  final result = await getShopProductsUseCase(
    searchQuery: filter.searchQuery,
    sortOption: filter.sortOption,
    minPrice: filter.minPrice,
    maxPrice: filter.maxPrice,
    types: filter.types,
    userLocation: filter.userLocation,
  );
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

/// 強制刷新商品列表
Future<void> refreshShopProducts(final WidgetRef ref, final ShopFilter filter) async {
  try {
    // 1. Refresh Categories
    final getProductCategories = ref.read(getProductCategoriesUseCaseProvider);
    await getProductCategories(forceRefresh: true);
    ref.invalidate(productCategoriesProvider);

    // 2. Refresh Products
    final _ = await ref.refresh(shopProductsProvider(filter).future);
  } catch (_) {
    // Provider 刷新失敗時，忽略異常，讓 UI 顯示 ErrorView 或舊資料
  }
}

@riverpod
Future<UserLocation?> userLocation(final Ref ref) async {
  final recommendNearbyShops = await ref.watch(recommendNearbyShopsProvider.future);

  if (!recommendNearbyShops) {
    return null;
  }

  final locationService = ref.watch(locationServiceProvider);
  return locationService.getUserLocation();
}
