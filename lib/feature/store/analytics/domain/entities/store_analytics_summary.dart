import 'package:freezed_annotation/freezed_annotation.dart';

part 'store_analytics_summary.freezed.dart';

@freezed
sealed class StoreAnalyticsSummary with _$StoreAnalyticsSummary {
  const factory StoreAnalyticsSummary({
    required final int viewCount,
    required final int tryonCount,
    required final int purchaseClickCount,
  }) = _StoreAnalyticsSummary;
}
