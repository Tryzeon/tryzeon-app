import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';

import '../../domain/entities/analytics_event.dart';
import '../../domain/entities/analytics_event_type.dart';
import '../models/analytics_event_model.dart';

import 'analytics_mappr.auto_mappr.dart';

/// AutoMappr configuration for Analytics module
@AutoMappr([
  // Main event mappings with custom field mapping for eventType
  MapType<AnalyticsEventModel, AnalyticsEvent>(
    fields: [Field('eventType', custom: AnalyticsMappr.stringToEventType)],
  ),
  MapType<AnalyticsEvent, AnalyticsEventModel>(
    fields: [Field('eventType', custom: AnalyticsMappr.eventTypeToString)],
  ),
])
class AnalyticsMappr extends $AnalyticsMappr {
  const AnalyticsMappr();

  static AnalyticsEventType stringToEventType(final AnalyticsEventModel model) {
    return AnalyticsEventType.values.firstWhere(
      (final type) => type.value == model.eventType,
      orElse: () => AnalyticsEventType.tryOn,
    );
  }

  static String eventTypeToString(final AnalyticsEvent event) => event.eventType.value;
}
