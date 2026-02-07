import 'package:freezed_annotation/freezed_annotation.dart';

part 'store_analytics_summary.freezed.dart';

@freezed
sealed class StoreAnalyticsSummary with _$StoreAnalyticsSummary {
  const factory StoreAnalyticsSummary({
    required final int totalViewCount,
    required final int totalTryonCount,
    required final int totalPurchaseClickCount,
  }) = _StoreAnalyticsSummary;
}
