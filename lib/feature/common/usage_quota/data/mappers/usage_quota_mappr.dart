import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/feature/common/usage_quota/data/dtos/usage_quota_dto.dart';
import 'package:tryzeon/feature/common/usage_quota/data/mappers/usage_quota_mappr.auto_mappr.dart';
import 'package:tryzeon/feature/common/usage_quota/domain/entities/usage_quota.dart';

@AutoMappr([
  MapType<FeatureQuotaDto, FeatureQuota>(),
  MapType<UsageQuotaDto, UsageQuota>(),
])
class UsageQuotaMappr extends $UsageQuotaMappr {
  const UsageQuotaMappr();
}
