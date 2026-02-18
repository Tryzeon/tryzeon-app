import 'package:tryzeon/app_mappr.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/store/analytics/data/datasources/store_analytics_local_datasource.dart';
import 'package:tryzeon/feature/store/analytics/data/datasources/store_analytics_remote_datasource.dart';
import 'package:tryzeon/feature/store/analytics/data/models/store_analytics_summary_model.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/store_analytics_summary.dart';
import 'package:tryzeon/feature/store/analytics/domain/repositories/store_analytics_repository.dart';
import 'package:typed_result/typed_result.dart';

class StoreAnalyticsRepositoryImpl implements StoreAnalyticsRepository {
  StoreAnalyticsRepositoryImpl({
    required final StoreAnalyticsRemoteDataSource remoteDataSource,
    required final StoreAnalyticsLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final StoreAnalyticsRemoteDataSource _remoteDataSource;
  final StoreAnalyticsLocalDataSource _localDataSource;
  static const _mappr = AppMappr();

  @override
  Future<Result<StoreAnalyticsSummary, Failure>> getStoreAnalyticsSummary(
    final String storeId, {
    final int? year,
    final int? month,
  }) async {
    try {
      final now = DateTime.now();
      // 判斷是否為過去的月份 (且非 All time)
      // 如果 year/month 為 null (All time)，或是當前月份/未來，則不讀/存 cache
      final isPastMonth =
          year != null &&
          month != null &&
          (year < now.year || (year == now.year && month < now.month));

      if (isPastMonth) {
        final cachedSummary = await _localDataSource.getStoreAnalyticsSummary(
          storeId,
          year,
          month,
        );

        if (cachedSummary != null) {
          final summary = _mappr
              .convert<StoreAnalyticsSummaryModel, StoreAnalyticsSummary>(cachedSummary);
          return Ok(summary);
        }
      }

      final remoteSummary = await _remoteDataSource.getStoreAnalyticsSummary(
        storeId,
        year: year,
        month: month,
      );

      if (isPastMonth) {
        await _localDataSource.saveStoreAnalyticsSummary(
          remoteSummary,
          storeId: storeId,
          year: year,
          month: month,
        );
      }

      final summary = _mappr
          .convert<StoreAnalyticsSummaryModel, StoreAnalyticsSummary>(remoteSummary);
      return Ok(summary);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get store analytics summary', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
