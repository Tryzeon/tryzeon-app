import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/product_analytics_summary.dart';
import 'package:tryzeon/feature/store/analytics/domain/repositories/product_analytics_repository.dart';
import 'package:typed_result/typed_result.dart';

class GetProductAnalyticsSummaries {
  GetProductAnalyticsSummaries(this._analyticsRepository);

  final ProductAnalyticsRepository _analyticsRepository;

  Future<Result<List<ProductAnalyticsSummary>, Failure>> call({
    required final String storeId,
    final int? year,
    final int? month,
  }) async {
    return _analyticsRepository.getProductAnalyticsSummaries(
      storeId,
      year: year,
      month: month,
    );
  }
}
