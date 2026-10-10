import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/product_analytics_summary.dart';

part 'product_sort_condition.freezed.dart';

enum ProductField { name, price, createdAt, updatedAt }

enum AnalyticsMetric {
  viewCount,
  tryonCount,
  purchaseClickCount;

  int countIn(final ProductAnalyticsSummary summary) => switch (this) {
    AnalyticsMetric.viewCount => summary.viewCount,
    AnalyticsMetric.tryonCount => summary.tryonCount,
    AnalyticsMetric.purchaseClickCount => summary.purchaseClickCount,
  };
}

@freezed
sealed class SortKey with _$SortKey {
  const factory SortKey.product(final ProductField field) = ProductSortKey;
  const factory SortKey.analytics(final AnalyticsMetric metric) =
      AnalyticsSortKey;
  const SortKey._();

  /// The direction an owner expects on first picking this key: names and
  /// prices read low to high, dates and counts lead with the newest or most.
  bool get defaultAscending => switch (this) {
    ProductSortKey(:final field) => switch (field) {
      ProductField.name || ProductField.price => true,
      ProductField.createdAt || ProductField.updatedAt => false,
    },
    AnalyticsSortKey() => false,
  };
}

@freezed
sealed class SortCondition with _$SortCondition {
  const factory SortCondition({
    required final SortKey key,
    required final bool ascending,
  }) = _SortCondition;
  const SortCondition._();

  factory SortCondition.byDefault(final SortKey key) =>
      SortCondition(key: key, ascending: key.defaultAscending);

  static const defaultSort = SortCondition(
    key: SortKey.product(ProductField.createdAt),
    ascending: false,
  );
}
