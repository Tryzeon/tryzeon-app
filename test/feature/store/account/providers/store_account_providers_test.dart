import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/store/account/providers/store_account_providers.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';
import 'package:tryzeon/feature/store/product/providers/store_product_providers.dart';

import '../../../../support/store_test_doubles.dart';

void main() {
  test('topTriedOnProducts joins products with summaries', () async {
    final container = ProviderContainer(
      overrides: [
        productsProvider.overrideWith(
          () => FakeProducts([product('a'), product('b')]),
        ),
        productAnalyticsSummariesProvider.overrideWith(
          () => FakeAnalyticsSummaries(
            (final _) async => [
              summary('a', views: 100, tryons: 10),
              summary('b', views: 50, tryons: 20),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final ranked = await container.read(topTriedOnProductsProvider.future);

    expect(ranked.map((final r) => r.product.name), ['b', 'a']);
  });
}
