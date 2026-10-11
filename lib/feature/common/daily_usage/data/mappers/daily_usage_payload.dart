import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/common/daily_usage/data/dtos/daily_usage_dto.dart';
import 'package:tryzeon/feature/common/daily_usage/data/mappers/daily_usage_mappr.dart';
import 'package:tryzeon/feature/common/daily_usage/domain/entities/daily_usage.dart';

/// The tryon and chat edge functions inline this snapshot in both success
/// bodies and 429 rate-limit payloads so the client can refresh the usage
/// cache without an extra round trip.
DailyUsage parseDailyUsagePayload(final Map<String, dynamic> json) =>
    const DailyUsageMappr().convert<DailyUsageDto, DailyUsage>(
      DailyUsageDto.fromJson(json),
    );

/// For payloads read while already handling a response or an error: a missing
/// or malformed snapshot only skips the cache refresh, it never fails the
/// caller.
DailyUsage? tryParseDailyUsagePayload(final Object? raw) {
  if (raw is! Map<String, dynamic>) return null;
  try {
    return parseDailyUsagePayload(raw);
  } catch (e, stackTrace) {
    AppLogger.warning('Malformed daily usage payload', e, stackTrace);
    return null;
  }
}
