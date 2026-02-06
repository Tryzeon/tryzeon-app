import 'package:tryzeon/feature/store/analytics/data/collections/store_analytics_collection.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/store_analytics_summary.dart';

extension StoreAnalyticsCollectionExtension on StoreAnalyticsCollection {
  StoreAnalyticsSummary toEntity() {
    return StoreAnalyticsSummary(
      totalViewCount: totalViewCount,
      totalTryonCount: totalTryonCount,
      totalPurchaseClickCount: totalPurchaseClickCount,
    );
  }
}

extension StoreAnalyticsSummaryExtension on StoreAnalyticsSummary {
  StoreAnalyticsCollection toCollection({
    required final String storeId,
    required final int year,
    required final int month,
  }) {
    return StoreAnalyticsCollection()
      ..storeId = storeId
      ..year = year
      ..month = month
      ..totalViewCount = totalViewCount
      ..totalTryonCount = totalTryonCount
      ..totalPurchaseClickCount = totalPurchaseClickCount
      ..updatedAt = DateTime.now();
  }
}
