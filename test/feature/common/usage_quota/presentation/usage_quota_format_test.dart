import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/feature/common/usage_quota/domain/entities/usage_quota.dart';
import 'package:tryzeon/feature/common/usage_quota/presentation/usage_quota_format.dart';

void main() {
  UsageQuota quotaOf(final QuotaPeriod period, {final DateTime? resetsAt}) =>
      UsageQuota(
        tier: period == QuotaPeriod.day
            ? AppSubscriptionTier.free
            : AppSubscriptionTier.pro,
        period: period,
        resetsAt: resetsAt ?? DateTime.utc(2026, 11, 4, 16),
        tryonImage: const FeatureQuota(used: 0, quota: 10),
        tryonVideo: const FeatureQuota(used: 0, quota: 0),
      );

  test('names the period the quota counts over', () {
    expect(periodLabel(QuotaPeriod.month), '本期');
    expect(periodLabel(QuotaPeriod.day), '今日');
  });

  test('a cycle quota labels its reset as M/D in Taipei time', () {
    expect(resetLabel(quotaOf(QuotaPeriod.month)), '11/5');
    expect(
      resetLabel(
        quotaOf(
          QuotaPeriod.month,
          resetsAt: DateTime.utc(2026, 11, 4, 15, 59, 59),
        ),
      ),
      '11/4',
    );
  });

  test('a daily quota has no reset label', () {
    expect(resetLabel(quotaOf(QuotaPeriod.day)), isNull);
  });

  test('a daily quota runs out today without a reset date', () {
    final quota = quotaOf(QuotaPeriod.day);

    expect(exhaustedLabel(quota), '今日次數已用完');
    expect(exhaustedLabel(quota, feature: '影片試穿'), '今日影片試穿次數已用完');
  });

  test('a cycle quota runs out with its reset date', () {
    final quota = quotaOf(QuotaPeriod.month);

    expect(exhaustedLabel(quota), '本期次數已用完，11/5 重置');
    expect(exhaustedLabel(quota, feature: '試穿'), '本期試穿次數已用完，11/5 重置');
  });

  test('the remaining count never names the reset date', () {
    expect(remainingLabel(quotaOf(QuotaPeriod.day), 7), '今日剩 7 次');
    expect(remainingLabel(quotaOf(QuotaPeriod.month), 238), '本期剩 238 次');
  });
}
