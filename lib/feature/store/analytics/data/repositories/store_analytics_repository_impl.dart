import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/store/analytics/data/datasources/store_analytics_remote_datasource.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/store_analytics_summary.dart';
import 'package:tryzeon/feature/store/analytics/domain/repositories/store_analytics_repository.dart';
import 'package:typed_result/typed_result.dart';

class StoreAnalyticsRepositoryImpl implements StoreAnalyticsRepository {
  StoreAnalyticsRepositoryImpl(this._remoteDataSource);

  final StoreAnalyticsRemoteDataSource _remoteDataSource;

  @override
  Future<Result<StoreAnalyticsSummary, Failure>> getStoreAnalyticsSummary(
    final String storeId, {
    final int? year,
    final int? month,
  }) async {
    try {
      final summary = await _remoteDataSource.getStoreAnalyticsSummary(
        storeId,
        year: year,
        month: month,
      );
      return Ok(summary);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get store analytics summary', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
