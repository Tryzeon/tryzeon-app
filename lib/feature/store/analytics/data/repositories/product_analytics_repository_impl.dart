import 'package:tryzeon/core/data/errors/map_exception_to_failure.dart';
import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/store/analytics/data/datasources/product_analytics_local_datasource.dart';
import 'package:tryzeon/feature/store/analytics/data/datasources/product_analytics_remote_datasource.dart';
import 'package:tryzeon/feature/store/analytics/data/dtos/product_analytics_summary_dto.dart';
import 'package:tryzeon/feature/store/analytics/data/mappers/store_analytics_mappr.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/product_analytics_summary.dart';
import 'package:tryzeon/feature/store/analytics/domain/repositories/product_analytics_repository.dart';
import 'package:typed_result/typed_result.dart';

class ProductAnalyticsRepositoryImpl implements ProductAnalyticsRepository {
  ProductAnalyticsRepositoryImpl({
    required final ProductAnalyticsRemoteDataSource remoteDataSource,
    required final ProductAnalyticsLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final ProductAnalyticsRemoteDataSource _remoteDataSource;
  final ProductAnalyticsLocalDataSource _localDataSource;
  static const _mappr = StoreAnalyticsMappr();

  @override
  Future<Result<List<ProductAnalyticsSummary>, Failure>>
  getProductAnalyticsSummaries(
    final String storeId, {
    required final int year,
    required final int month,
  }) async {
    final now = DateTime.now();
    final isPastMonth =
        year < now.year || (year == now.year && month < now.month);

    if (isPastMonth) {
      try {
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
      } catch (e, stackTrace) {
        AppLogger.warning(
          'Local cache read failed, falling back to remote',
          e,
          stackTrace,
        );
      }
    }

    final List<ProductAnalyticsSummary> summaries;
    try {
      summaries = _mappr
          .convertList<ProductAnalyticsSummaryDto, ProductAnalyticsSummary>(
            await _remoteDataSource.getProductAnalyticsSummaries(
              storeId,
              year: year,
              month: month,
            ),
          );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to get product analytics summaries',
        e,
        stackTrace,
      );
      return Err(mapExceptionToFailure(e));
    }

    if (isPastMonth) {
      try {
        if (summaries.isEmpty) {
          await _localDataSource.markProductAnalyticsSummariesEmpty(
            storeId,
            year,
            month,
          );
        } else {
          await _localDataSource.saveProductAnalyticsSummaries(
            storeId,
            year,
            month,
            summaries,
          );
        }
      } catch (e, stackTrace) {
        AppLogger.warning(
          'Failed to save product analytics summaries to cache',
          e,
          stackTrace,
        );
      }
    }

    return Ok(summaries);
  }
}
