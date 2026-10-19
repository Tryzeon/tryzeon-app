import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/feature/common/usage_quota/data/mappers/usage_quota_payload.dart';
import 'package:tryzeon/feature/common/usage_quota/domain/entities/usage_quota.dart';

void main() {
  test('decodes the quota snapshot inlined by the edge functions', () {
    final quota = parseUsageQuotaPayload({
      'tier': 'pro',
      'period': 'month',
      'resetsAt': '2026-11-04T16:00:00Z',
      'tryonImage': {'used': 12, 'quota': 250},
      'tryonVideo': {'used': 1, 'quota': 3},
    });

    expect(
      quota,
      UsageQuota(
        tier: AppSubscriptionTier.pro,
        period: QuotaPeriod.month,
        resetsAt: DateTime.utc(2026, 11, 4, 16),
        tryonImage: const FeatureQuota(used: 12, quota: 250),
        tryonVideo: const FeatureQuota(used: 1, quota: 3),
      ),
    );
    expect(quota.tryonVideo.quota, 3);
    expect(quota.tryonImage.remaining, 238);
    expect(quota.hasVideoAccess, isTrue);
  });

  test('an incomplete snapshot parses to null instead of throwing', () {
    expect(tryParseUsageQuotaPayload({'tier': 'pro'}), isNull);
  });

  test('a non-object snapshot parses to null', () {
    expect(tryParseUsageQuotaPayload('not a map'), isNull);
  });
}
