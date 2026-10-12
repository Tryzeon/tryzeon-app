import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/core/modules/analytics/data/dtos/analytics_event_dto.dart';
import 'package:tryzeon/core/modules/analytics/data/mappers/analytics_mappr.auto_mappr.dart';
import 'package:tryzeon/core/modules/analytics/domain/entities/analytics_event.dart';

@AutoMappr([
  MapType<AnalyticsEvent, AnalyticsEventDto>(
    fields: [Field('eventType', custom: AnalyticsMappr.eventTypeToString)],
  ),
])
class AnalyticsMappr extends $AnalyticsMappr {
  const AnalyticsMappr();

  static String eventTypeToString(final AnalyticsEvent event) =>
      event.eventType.value;
}
