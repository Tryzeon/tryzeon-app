import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';

part 'usage_quota.freezed.dart';

enum QuotaPeriod { day, month }

@freezed
sealed class FeatureQuota with _$FeatureQuota {
  const factory FeatureQuota({
    required final int used,
    required final int quota,
  }) = _FeatureQuota;

  const FeatureQuota._();

  int get remaining => max(0, quota - used);

  bool get isExhausted => remaining == 0;
}

@freezed
sealed class UsageQuota with _$UsageQuota {
  const factory UsageQuota({
    required final AppSubscriptionTier tier,
    required final QuotaPeriod period,
    required final DateTime resetsAt,
    required final FeatureQuota tryonImage,
    required final FeatureQuota tryonVideo,
  }) = _UsageQuota;

  const UsageQuota._();

  bool get hasVideoAccess => tryonVideo.quota > 0;
}
