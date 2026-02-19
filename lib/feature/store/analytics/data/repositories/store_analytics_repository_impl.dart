import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/store/analytics/data/datasources/store_analytics_local_datasource.dart';
import 'package:tryzeon/feature/store/analytics/data/datasources/store_analytics_remote_datasource.dart';
import 'package:tryzeon/feature/store/analytics/data/models/store_analytics_summary_model.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/store_analytics_summary.dart';
import 'package:tryzeon/feature/store/analytics/domain/repositories/store_analytics_repository.dart';
import 'package:tryzeon/feature/store/data/mappers/store_mappr.dart';
import 'package:typed_result/typed_result.dart';

class StoreAnalyticsRepositoryImpl implements StoreAnalyticsRepository {
  StoreAnalyticsRepositoryImpl({
    required final StoreAnalyticsRemoteDataSource remoteDataSource,
    required final StoreAnalyticsLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final StoreAnalyticsRemoteDataSource _remoteDataSource;
  final StoreAnalyticsLocalDataSource _localDataSource;
  static const _mappr = StoreMappr();

  @override
  Future<Result<StoreAnalyticsSummary, Failure>> getStoreAnalyticsSummary(
    final String storeId, {
    final int? year,
    final int? month,
  }) async {
    try {
      final now = DateTime.now();
      final isAllTime = year == null || month == null;

      // All time: fetch all rows, aggregate client-side
      if (isAllTime) {
        final summaries = await _remoteDataSource.getAllStoreAnalyticsSummaries(storeId);
        final summary = StoreAnalyticsSummary(
          viewCount: summaries.fold(0, (final sum, final s) => sum + s.viewCount),
          tryonCount: summaries.fold(0, (final sum, final s) => sum + s.tryonCount),
          purchaseClickCount: summaries.fold(
            0,
            (final sum, final s) => sum + s.purchaseClickCount,
          ),
        );
        return Ok(summary);
      }

      // 判斷是否為過去的月份
      final isPastMonth = year < now.year || (year == now.year && month < now.month);

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
        await _localDataSource.saveStoreAnalyticsSummary(remoteSummary);
      }

      final summary = _mappr.convert<StoreAnalyticsSummaryModel, StoreAnalyticsSummary>(
        remoteSummary,
      );
      return Ok(summary);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get store analytics summary', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
