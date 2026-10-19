import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/data/errors/map_exception_to_failure.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/feature/common/usage_quota/domain/entities/usage_quota.dart';
import 'package:tryzeon/feature/personal/tryon/data/exceptions/quota_exceeded_exception.dart';
import 'package:tryzeon/feature/personal/tryon/domain/failures/quota_exceeded_failure.dart';

void main() {
  final quota = UsageQuota(
    tier: AppSubscriptionTier.free,
    period: QuotaPeriod.day,
    resetsAt: DateTime.utc(2026, 10, 19, 16),
    tryonImage: const FeatureQuota(used: 10, quota: 10),
    tryonVideo: const FeatureQuota(used: 0, quota: 0),
  );

  test('carries its quota into the failure', () {
    final failure = QuotaExceededException(quota: quota).toFailure();

    expect(
      failure,
      isA<QuotaExceededFailure>().having((final f) => f.quota, 'quota', quota),
    );
    expect(
      mapExceptionToFailure(QuotaExceededException(quota: quota)),
      QuotaExceededFailure(quota: quota),
    );
  });

  test('is a spent quota, not a rate limit', () {
    expect(QuotaExceededFailure(quota: quota), isNot(isA<RateLimitFailure>()));
    expect(QuotaExceededFailure(quota: quota).displayMessage(), '試穿次數已用完');
  });
}
