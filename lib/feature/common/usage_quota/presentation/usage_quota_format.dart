import 'package:tryzeon/feature/common/usage_quota/domain/entities/usage_quota.dart';

// Taiwan observes no DST, so a fixed offset is exact without a tz database.
const _taipeiUtcOffset = Duration(hours: 8);

String periodLabel(final QuotaPeriod period) => switch (period) {
  QuotaPeriod.day => '今日',
  QuotaPeriod.month => '本期',
};

String resetDateLabel(final DateTime resetsAt) {
  final taipei = resetsAt.toUtc().add(_taipeiUtcOffset);
  return '${taipei.month}/${taipei.day}';
}
