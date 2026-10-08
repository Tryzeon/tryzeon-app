import 'package:tryzeon/core/modules/analytics/domain/entities/analytics_event.dart';

abstract class AnalyticsEventQueue {
  void enqueue(final AnalyticsEvent event);

  Future<void> forceFlush();
}
