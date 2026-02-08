import 'package:freezed_annotation/freezed_annotation.dart';

part 'analytics_event.freezed.dart';

@freezed
sealed class AnalyticsEvent with _$AnalyticsEvent {
  const factory AnalyticsEvent({
    required final String productId,
    required final String storeId,
    required final String eventType,
  }) = _AnalyticsEvent;
}
