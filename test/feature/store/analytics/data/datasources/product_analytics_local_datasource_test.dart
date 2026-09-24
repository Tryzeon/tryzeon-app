import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/feature/store/analytics/data/collections/product_analytics_cache.dart';
import 'package:tryzeon/feature/store/analytics/data/datasources/product_analytics_local_datasource.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/product_analytics_summary.dart';

import '../../../../../support/isar_test_harness.dart';

void main() {
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  late TestIsar harness;

  setUp(() async {
    harness = await openTestIsar();
  });

  tearDown(() async {
    await harness.dispose();
  });

  ProductAnalyticsLocalDataSource build() => ProductAnalyticsLocalDataSource(
    harness.service,
    CacheEntryLocalDataSource(harness.service),
  );

  const first = [
    ProductAnalyticsSummary(
      productId: 'p1',
      viewCount: 10,
      tryonCount: 2,
      purchaseClickCount: 1,
    ),
    ProductAnalyticsSummary(
      productId: 'p2',
      viewCount: 5,
      tryonCount: 0,
      purchaseClickCount: 0,
    ),
  ];
  const second = [
    ProductAnalyticsSummary(
      productId: 'p1',
      viewCount: 12,
      tryonCount: 3,
      purchaseClickCount: 1,
    ),
  ];

  test('reads back exactly the summaries it saved for that store and month', () async {
    final local = build();

    await local.saveProductAnalyticsSummaries('s1', 2026, 5, first);
    await local.saveProductAnalyticsSummaries('s2', 2026, 5, second);

    final lookup = await local.getProductAnalyticsSummaries('s1', 2026, 5);

    expect(
      (lookup as CacheHit<List<ProductAnalyticsSummary>>).data,
      unorderedEquals(first),
    );
  });

  test('saving the same month again upserts instead of duplicating', () async {
    final local = build();

    await local.saveProductAnalyticsSummaries('s1', 2026, 5, first);
    await local.saveProductAnalyticsSummaries('s1', 2026, 5, second);

    final rows = await harness.isar.productAnalyticsCaches
        .filter()
        .storeIdEqualTo('s1')
        .productIdEqualTo('p1')
        .findAll();

    expect(rows, hasLength(1));
    expect(rows.single.viewCount, 12);
    expect(rows.single.year, 2026);
    expect(rows.single.month, 5);
  });
}
