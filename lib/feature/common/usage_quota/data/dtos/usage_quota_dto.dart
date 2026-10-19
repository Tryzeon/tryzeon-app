import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/feature/common/usage_quota/domain/entities/usage_quota.dart';

part 'usage_quota_dto.g.dart';

@JsonSerializable(checked: true, createToJson: false)
class UsageQuotaDto {
  const UsageQuotaDto({
    required this.tier,
    required this.period,
    required this.resetsAt,
    required this.tryonImage,
    required this.tryonVideo,
  });

  factory UsageQuotaDto.fromJson(final Map<String, dynamic> json) =>
      _$UsageQuotaDtoFromJson(json);

  final AppSubscriptionTier tier;
  final QuotaPeriod period;
  final DateTime resetsAt;
  final FeatureQuotaDto tryonImage;
  final FeatureQuotaDto tryonVideo;
}

@JsonSerializable(checked: true, createToJson: false)
class FeatureQuotaDto {
  const FeatureQuotaDto({required this.used, required this.quota});

  factory FeatureQuotaDto.fromJson(final Map<String, dynamic> json) =>
      _$FeatureQuotaDtoFromJson(json);

  final int used;
  final int quota;
}
