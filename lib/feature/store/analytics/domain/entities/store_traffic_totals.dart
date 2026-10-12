import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/product_analytics_summary.dart';

part 'store_traffic_totals.freezed.dart';

@freezed
sealed class StoreTrafficTotals with _$StoreTrafficTotals {
  const factory StoreTrafficTotals({
    required final int viewCount,
    required final int tryonCount,
    required final int purchaseClickCount,
  }) = _StoreTrafficTotals;

  const StoreTrafficTotals._();

  factory StoreTrafficTotals.fromSummaries(
    final Iterable<ProductAnalyticsSummary> summaries,
  ) {
    var views = 0;
    var tryons = 0;
    var clicks = 0;
    for (final s in summaries) {
      views += s.viewCount;
      tryons += s.tryonCount;
      clicks += s.purchaseClickCount;
    }
    return StoreTrafficTotals(
      viewCount: views,
      tryonCount: tryons,
      purchaseClickCount: clicks,
    );
  }

  // Both rates divide by views: try-ons are recorded server-side and need not
  // follow a view, and purchase clicks need not follow a try-on, so a
  // step-over-step ratio could exceed 100%.
  double? get tryonRate => _perView(tryonCount);

  double? get purchaseClickRate => _perView(purchaseClickCount);

  double? _perView(final int count) =>
      viewCount == 0 ? null : count / viewCount;
}
