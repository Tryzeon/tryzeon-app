import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/feature/store/analytics/data/collections/product_analytics_cache.dart';
import 'package:tryzeon/feature/store/analytics/data/dtos/product_analytics_summary_dto.dart';
import 'package:tryzeon/feature/store/analytics/data/mappers/store_analytics_mappr.auto_mappr.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/product_analytics_summary.dart';

@AutoMappr([
  MapType<ProductAnalyticsSummaryDto, ProductAnalyticsSummary>(),
  MapType<ProductAnalyticsSummary, ProductAnalyticsCache>(),
  MapType<ProductAnalyticsCache, ProductAnalyticsSummary>(),
])
class StoreAnalyticsMappr extends $StoreAnalyticsMappr {
  const StoreAnalyticsMappr();
}
