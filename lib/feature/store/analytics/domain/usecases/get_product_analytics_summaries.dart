import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/product_analytics_summary.dart';
import 'package:tryzeon/feature/store/analytics/domain/repositories/product_analytics_repository.dart';
import 'package:typed_result/typed_result.dart';

part 'get_product_analytics_summaries.freezed.dart';

@freezed
sealed class GetProductAnalyticsSummariesParams
    with _$GetProductAnalyticsSummariesParams {
  const factory GetProductAnalyticsSummariesParams({
    required final String storeId,
    required final int year,
    required final int month,
  }) = _GetProductAnalyticsSummariesParams;
}

class GetProductAnalyticsSummaries {
  GetProductAnalyticsSummaries(this._analyticsRepository);

  final ProductAnalyticsRepository _analyticsRepository;

  Future<Result<List<ProductAnalyticsSummary>, Failure>> call(
    final GetProductAnalyticsSummariesParams params,
  ) {
    return _analyticsRepository.getProductAnalyticsSummaries(
      params.storeId,
      year: params.year,
      month: params.month,
    );
  }
}
