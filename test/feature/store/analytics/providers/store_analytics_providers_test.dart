import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/store_traffic_totals.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';

import '../../../../support/store_test_doubles.dart';

void main() {
  test('storeTrafficTotals aggregates the month summaries', () async {
    final container = ProviderContainer(
      overrides: [
        productAnalyticsSummariesProvider.overrideWith(
          () => FakeAnalyticsSummaries(
            (final _) async => [
              summary('a', views: 100, tryons: 10, clicks: 2),
              summary('b', views: 50, tryons: 20, clicks: 1),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final totals = await container.read(storeTrafficTotalsProvider.future);

    expect(
      totals,
      const StoreTrafficTotals(
        viewCount: 150,
        tryonCount: 30,
        purchaseClickCount: 3,
      ),
    );
  });
}
