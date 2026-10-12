import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/store_traffic_totals.dart';

import '../../../../../support/store_test_doubles.dart';

void main() {
  test('sums every summary', () {
    final totals = StoreTrafficTotals.fromSummaries([
      summary('a', views: 600, tryons: 100, clicks: 50),
      summary('b', views: 400, tryons: 80, clicks: 40),
    ]);

    expect(
      totals,
      const StoreTrafficTotals(
        viewCount: 1000,
        tryonCount: 180,
        purchaseClickCount: 90,
      ),
    );
  });

  test('both rates divide by views', () {
    const totals = StoreTrafficTotals(
      viewCount: 1000,
      tryonCount: 180,
      purchaseClickCount: 90,
    );

    expect(totals.tryonRate, closeTo(0.18, 1e-9));
    expect(totals.purchaseClickRate, closeTo(0.09, 1e-9));
  });

  test('rates are null without views', () {
    const totals = StoreTrafficTotals(
      viewCount: 0,
      tryonCount: 5,
      purchaseClickCount: 0,
    );

    expect(totals.tryonRate, isNull);
    expect(totals.purchaseClickRate, isNull);
  });

  test('try-ons may exceed views', () {
    const totals = StoreTrafficTotals(
      viewCount: 100,
      tryonCount: 150,
      purchaseClickCount: 0,
    );

    expect(totals.tryonRate, closeTo(1.5, 1e-9));
  });

  test('empty input is all zeros', () {
    expect(
      StoreTrafficTotals.fromSummaries(const []),
      const StoreTrafficTotals(
        viewCount: 0,
        tryonCount: 0,
        purchaseClickCount: 0,
      ),
    );
  });
}
