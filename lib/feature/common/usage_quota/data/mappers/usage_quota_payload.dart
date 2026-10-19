import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/common/usage_quota/data/dtos/usage_quota_dto.dart';
import 'package:tryzeon/feature/common/usage_quota/data/mappers/usage_quota_mappr.dart';
import 'package:tryzeon/feature/common/usage_quota/domain/entities/usage_quota.dart';

UsageQuota parseUsageQuotaPayload(final Map<String, dynamic> json) =>
    const UsageQuotaMappr().convert<UsageQuotaDto, UsageQuota>(
      UsageQuotaDto.fromJson(json),
    );

UsageQuota? tryParseUsageQuotaPayload(final Object? raw) {
  if (raw is! Map<String, dynamic>) return null;
  try {
    return parseUsageQuotaPayload(raw);
  } catch (e, stackTrace) {
    AppLogger.warning('Malformed usage quota payload', e, stackTrace);
    return null;
  }
}
