import 'package:tryzeon/feature/store/analytics/domain/entities/product_analytics_summary.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';

typedef RankedProduct = ({Product product, int tryonCount});

const _topCount = 5;

List<RankedProduct> rankTopTriedOnProducts(
  final List<Product> products,
  final List<ProductAnalyticsSummary> summaries,
) {
  final productsById = {for (final p in products) p.id: p};
  final matched = [
    for (final s in summaries)
      if (productsById[s.productId] case final product? when s.tryonCount > 0)
        (product: product, summary: s),
  ];
  matched.sort((final a, final b) {
    final byTryon = b.summary.tryonCount.compareTo(a.summary.tryonCount);
    if (byTryon != 0) return byTryon;
    final byView = b.summary.viewCount.compareTo(a.summary.viewCount);
    if (byView != 0) return byView;
    return a.product.name.compareTo(b.product.name);
  });
  return [
    for (final m in matched.take(_topCount))
      (product: m.product, tryonCount: m.summary.tryonCount),
  ];
}
