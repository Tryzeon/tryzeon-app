import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/store/analytics/presentation/state/analytics_months.dart';

void main() {
  final now = DateTime(2026, 2, 15);

  test('lists every month since the store opened, newest first', () {
    expect(analyticsMonthsSince(DateTime(2025, 11, 30), now: now), [
      (year: 2026, month: 2),
      (year: 2026, month: 1),
      (year: 2025, month: 12),
      (year: 2025, month: 11),
    ]);
  });

  test('without an opening date only the current month is offered', () {
    expect(analyticsMonthsSince(null, now: now), [(year: 2026, month: 2)]);
  });

  test('an opening date in the future still offers the current month', () {
    expect(analyticsMonthsSince(DateTime(2026, 5, 1), now: now), [
      (year: 2026, month: 2),
    ]);
  });

  test('labels read as year and month', () {
    expect((year: 2026, month: 10).label, '2026 年 10 月');
  });
}
