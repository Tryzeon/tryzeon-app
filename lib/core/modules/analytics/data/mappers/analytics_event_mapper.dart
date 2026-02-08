import 'package:tryzeon/core/modules/analytics/data/models/analytics_event_model.dart';
import 'package:tryzeon/core/modules/analytics/domain/entities/analytics_event.dart';
import 'package:tryzeon/core/modules/analytics/domain/entities/analytics_event_type.dart';

/// Extension to map AnalyticsEvent entity to AnalyticsEventModel
extension AnalyticsEventEntityMapper on AnalyticsEvent {
  AnalyticsEventModel toModel() {
    return AnalyticsEventModel(
      productId: productId,
      storeId: storeId,
      eventType: eventType.value,
    );
  }
}

/// Extension to map AnalyticsEventModel to AnalyticsEvent entity
extension AnalyticsEventModelMapper on AnalyticsEventModel {
  AnalyticsEvent toEntity() {
    return AnalyticsEvent(
      productId: productId,
      storeId: storeId,
      eventType: AnalyticsEventType.values.firstWhere((final e) => e.value == eventType),
    );
  }
}
