import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/usage_quota/domain/entities/usage_quota.dart';
import 'package:tryzeon/feature/common/usage_quota/presentation/usage_quota_format.dart';

void main() {
  test('names the period the quota counts over', () {
    expect(periodLabel(QuotaPeriod.month), '本期');
    expect(periodLabel(QuotaPeriod.day), '今日');
  });

  test('formats the reset date as M/D in Taipei time', () {
    expect(resetDateLabel(DateTime.utc(2026, 11, 4, 16)), '11/5');
    expect(resetDateLabel(DateTime.utc(2026, 11, 4, 15, 59, 59)), '11/4');
  });
}
