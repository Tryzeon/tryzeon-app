import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';

import '../../domain/entities/analytics_event.dart';
import '../dtos/analytics_event_dto.dart';

import 'analytics_mappr.auto_mappr.dart';

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
