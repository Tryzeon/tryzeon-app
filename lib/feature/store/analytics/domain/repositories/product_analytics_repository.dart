import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/product_analytics_summary.dart';
import 'package:typed_result/typed_result.dart';

abstract class ProductAnalyticsRepository {
  Future<Result<List<ProductAnalyticsSummary>, Failure>> getProductAnalyticsSummaries(
    final String storeId, {
    final int? year,
    final int? month,
  });
}
