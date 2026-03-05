import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_analytics_summary.freezed.dart';

@freezed
sealed class ProductAnalyticsSummary with _$ProductAnalyticsSummary {
  const factory ProductAnalyticsSummary({
    required final String productId,
    required final int viewCount,
    required final int tryonCount,
    required final int purchaseClickCount,
  }) = _ProductAnalyticsSummary;
}
