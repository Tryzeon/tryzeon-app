import 'package:tryzeon/feature/store/analytics/domain/entities/store_analytics_summary.dart';

class StoreAnalyticsSummaryModel extends StoreAnalyticsSummary {
  const StoreAnalyticsSummaryModel({
    required super.totalTryonCount,
    required super.totalPurchaseClickCount,
  });

  factory StoreAnalyticsSummaryModel.fromJson(final Map<String, dynamic> json) {
    return StoreAnalyticsSummaryModel(
      totalTryonCount: json['tryon_count'] as int? ?? 0,
      totalPurchaseClickCount: json['purchase_click_count'] as int? ?? 0,
    );
  }
}
