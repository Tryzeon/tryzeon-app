import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/modules/analytics/domain/entities/analytics_event_type.dart';

part 'analytics_event.freezed.dart';

@freezed
sealed class AnalyticsEvent with _$AnalyticsEvent {
  const factory AnalyticsEvent({
    required final String productId,
    required final String storeId,
    required final AnalyticsEventType eventType,
  }) = _AnalyticsEvent;
}
