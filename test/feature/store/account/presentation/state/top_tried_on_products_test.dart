import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/store/account/presentation/state/top_tried_on_products.dart';

import '../../../../../support/store_test_doubles.dart';

List<String> names(final List<RankedProduct> ranked) =>
    ranked.map((final r) => r.product.name).toList();

void main() {
  test('orders by try-ons and keeps the top five', () {
    final products = [for (final n in 'abcdefghijk'.split('')) product(n)];
    final summaries = [
      for (final (i, n) in 'abcdefghijk'.split('').indexed)
        summary(n, tryons: i + 1),
    ];

    final ranked = rankTopTriedOnProducts(products, summaries);

    expect(names(ranked), 'kjihg'.split(''));
    expect(ranked.first.tryonCount, 11);
  });

  test('excludes products without try-ons', () {
    final ranked = rankTopTriedOnProducts(
      [product('a'), product('b')],
      [summary('a', views: 99), summary('b', tryons: 1)],
    );

    expect(names(ranked), ['b']);
  });

  test('ignores summaries of products that no longer exist', () {
    final ranked = rankTopTriedOnProducts(
      [product('a')],
      [summary('deleted', tryons: 50), summary('a', tryons: 1)],
    );

    expect(names(ranked), ['a']);
  });

  test('breaks ties by views, then by name', () {
    final ranked = rankTopTriedOnProducts(
      [product('z'), product('y'), product('x')],
      [
        summary('z', tryons: 3, views: 10),
        summary('y', tryons: 3, views: 20),
        summary('x', tryons: 3, views: 10),
      ],
    );

    expect(names(ranked), ['y', 'x', 'z']);
  });

  test('empty when nothing was tried on', () {
    expect(rankTopTriedOnProducts([product('a')], const []), isEmpty);
  });
}
