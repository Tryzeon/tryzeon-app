import 'package:freezed_annotation/freezed_annotation.dart';

part 'analytics_event.freezed.dart';
part 'analytics_event.g.dart';

@freezed
sealed class AnalyticsEvent with _$AnalyticsEvent {
  const factory AnalyticsEvent({
    required final String productId,
    required final String storeId,
    required final String eventType,
  }) = _AnalyticsEvent;

  factory AnalyticsEvent.fromJson(final Map<String, dynamic> json) =>
      _$AnalyticsEventFromJson(json);
}
