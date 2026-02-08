import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/analytics/data/services/analytics_event_queue_service.dart';
import 'package:tryzeon/core/modules/analytics/domain/entities/analytics_event.dart';
import 'package:tryzeon/core/modules/analytics/domain/entities/analytics_event_type.dart';
import 'package:tryzeon/core/modules/location/domain/entities/user_location.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/shop/data/datasources/ad_local_datasource.dart';
import 'package:tryzeon/feature/personal/shop/data/datasources/shop_remote_datasource.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/product_sort_option.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/repositories/shop_repository.dart';
import 'package:typed_result/typed_result.dart';

class ShopRepositoryImpl implements ShopRepository {
  ShopRepositoryImpl(
    this._remoteDataSource,
    this._adLocalDataSource,
    this._analyticsQueueService,
  );
  final ShopRemoteDataSource _remoteDataSource;
  final AdLocalDataSource _adLocalDataSource;
  final AnalyticsEventQueueService _analyticsQueueService;

  @override
  Future<Result<List<ShopProduct>, Failure>> getProducts({
    final String? searchQuery,
    final ProductSortOption sortOption = ProductSortOption.latest,
    final int? minPrice,
    final int? maxPrice,
    final Set<String>? types,
    final UserLocation? userLocation,
    final bool forceRefresh = false,
  }) async {
    try {
      final result = await _remoteDataSource.getProducts(
        searchQuery: searchQuery,
        sortOption: sortOption,
        minPrice: minPrice,
        maxPrice: maxPrice,
        types: types,
        userLocation: userLocation,
      );
      return Ok(result.map((final m) => m.toEntity()).toList());
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get product list', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> incrementTryonCount({
    required final String productId,
    required final String storeId,
  }) async {
    try {
      // Enqueue event instead of sending immediately
      _analyticsQueueService.enqueue(
        AnalyticsEvent(
          productId: productId,
          storeId: storeId,
          eventType: AnalyticsEventType.tryOn,
        ),
      );
      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to enqueue try-on event', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> incrementViewCount({
    required final String productId,
    required final String storeId,
  }) async {
    try {
      // Enqueue event instead of sending immediately
      _analyticsQueueService.enqueue(
        AnalyticsEvent(
          productId: productId,
          storeId: storeId,
          eventType: AnalyticsEventType.view,
        ),
      );
      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to enqueue view event', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> incrementPurchaseClickCount({
    required final String productId,
    required final String storeId,
  }) async {
    try {
      // Enqueue event instead of sending immediately
      _analyticsQueueService.enqueue(
        AnalyticsEvent(
          productId: productId,
          storeId: storeId,
          eventType: AnalyticsEventType.purchaseClick,
        ),
      );
      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to enqueue purchase click event', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<String>, Failure>> getAds({final bool forceRefresh = false}) async {
    try {
      final ads = await _adLocalDataSource.getAdImages(forceRefresh: forceRefresh);
      return Ok(ads);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get advertisements', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
