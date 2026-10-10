import 'package:flutter/material.dart';
import 'package:tryzeon/feature/store/product/presentation/state/product_sort_condition.dart';

extension AnalyticsMetricUi on AnalyticsMetric {
  IconData get icon => switch (this) {
    AnalyticsMetric.viewCount => Icons.visibility_outlined,
    AnalyticsMetric.tryonCount => Icons.checkroom_outlined,
    AnalyticsMetric.purchaseClickCount => Icons.north_east_rounded,
  };
}
