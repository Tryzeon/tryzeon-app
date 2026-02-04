import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/store_analytics_summary.dart';
import 'package:typed_result/typed_result.dart';

abstract class StoreAnalyticsRepository {
  Future<Result<StoreAnalyticsSummary, Failure>> getStoreAnalyticsSummary(
    final String storeId, {
    final int? year,
    final int? month,
  });
}
