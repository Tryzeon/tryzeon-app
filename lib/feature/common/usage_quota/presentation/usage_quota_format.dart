import 'package:tryzeon/feature/common/usage_quota/domain/entities/usage_quota.dart';

// Taiwan observes no DST, so a fixed offset is exact without a tz database.
const _taipeiUtcOffset = Duration(hours: 8);

String periodLabel(final QuotaPeriod period) => switch (period) {
  QuotaPeriod.day => '今日',
  QuotaPeriod.month => '本期',
};

String _taipeiMonthDay(final DateTime instant) {
  final taipei = instant.toUtc().add(_taipeiUtcOffset);
  return '${taipei.month}/${taipei.day}';
}

/// `M/D` in Taipei time for a monthly period; null for a daily one, whose
/// reset is always tomorrow and goes unsaid.
String? resetLabel(final UsageQuota quota) => switch (quota.period) {
  QuotaPeriod.day => null,
  QuotaPeriod.month => _taipeiMonthDay(quota.resetsAt),
};

String exhaustedLabel(final UsageQuota quota, {final String feature = ''}) {
  final label = '${periodLabel(quota.period)}$feature次數已用完';
  final reset = resetLabel(quota);
  return reset == null ? label : '$label，$reset 重置';
}

String remainingLabel(final UsageQuota quota, final int remaining) =>
    '${periodLabel(quota.period)}剩 $remaining 次';
