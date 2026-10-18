import 'package:tryzeon/feature/store/analytics/domain/entities/analytics_month.dart';

List<AnalyticsMonth> analyticsMonthsSince(
  final DateTime? openedAt, {
  required final DateTime now,
}) {
  final months = <AnalyticsMonth>[];
  var cursor = DateTime(now.year, now.month);
  final opened = openedAt?.toLocal();
  final first = opened == null ? cursor : DateTime(opened.year, opened.month);
  do {
    months.add((year: cursor.year, month: cursor.month));
    cursor = DateTime(cursor.year, cursor.month - 1);
  } while (!cursor.isBefore(first));
  return months;
}

extension AnalyticsMonthLabel on AnalyticsMonth {
  String get label => '$year 年 $month 月';
}
