import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/store/analytics/data/datasources/product_analytics_local_datasource.dart';
import 'package:tryzeon/feature/store/analytics/data/datasources/product_analytics_remote_datasource.dart';
import 'package:tryzeon/feature/store/analytics/data/dtos/product_analytics_summary_dto.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/product_analytics_summary.dart';
import 'package:tryzeon/feature/store/analytics/domain/repositories/product_analytics_repository.dart';
import 'package:tryzeon/feature/store/data/mappers/store_mappr.dart';
import 'package:typed_result/typed_result.dart';

class ProductAnalyticsRepositoryImpl implements ProductAnalyticsRepository {
  ProductAnalyticsRepositoryImpl({
    required final ProductAnalyticsRemoteDataSource remoteDataSource,
    required final ProductAnalyticsLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final ProductAnalyticsRemoteDataSource _remoteDataSource;
  final ProductAnalyticsLocalDataSource _localDataSource;
  static const _mappr = StoreMappr();

  @override
  Future<Result<List<ProductAnalyticsSummary>, Failure>> getProductAnalyticsSummaries(
    final String storeId, {
    final int? year,
    final int? month,
  }) async {
    try {
      final now = DateTime.now();
      final isAllTime = year == null || month == null;

      if (isAllTime) {
        final summaries = _mappr
            .convertList<ProductAnalyticsSummaryDto, ProductAnalyticsSummary>(
              await _remoteDataSource.getAllProductAnalyticsSummaries(storeId),
            );
        return Ok(_aggregateByProduct(summaries));
      }

      final isPastMonth = year < now.year || (year == now.year && month < now.month);

      if (isPastMonth) {
        final cached = await _localDataSource.getProductAnalyticsSummaries(
          storeId,
          year,
          month,
        );
        switch (cached) {
          case CacheHit<List<ProductAnalyticsSummary>>(:final data):
            return Ok(data);
          case CacheEmpty<List<ProductAnalyticsSummary>>():
            return const Ok([]);
          case CacheMiss<List<ProductAnalyticsSummary>>():
            break;
        }
      }

      final summaries = _mappr
          .convertList<ProductAnalyticsSummaryDto, ProductAnalyticsSummary>(
            await _remoteDataSource.getProductAnalyticsSummaries(
              storeId,
              year: year,
              month: month,
            ),
          );

      if (isPastMonth) {
        if (summaries.isEmpty) {
          await _localDataSource.markProductAnalyticsSummariesEmpty(storeId, year, month);
        } else {
          await _localDataSource.saveProductAnalyticsSummaries(
            storeId,
            year,
            month,
            summaries,
          );
        }
      }

      return Ok(summaries);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get product analytics summaries', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  List<ProductAnalyticsSummary> _aggregateByProduct(
    final List<ProductAnalyticsSummary> summaries,
  ) {
    final Map<String, ProductAnalyticsSummary> map = {};
    for (final s in summaries) {
      final existing = map[s.productId];
      map[s.productId] = existing == null
          ? s
          : existing.copyWith(
              viewCount: existing.viewCount + s.viewCount,
              tryonCount: existing.tryonCount + s.tryonCount,
              purchaseClickCount: existing.purchaseClickCount + s.purchaseClickCount,
            );
    }
    return map.values.toList();
  }
}
