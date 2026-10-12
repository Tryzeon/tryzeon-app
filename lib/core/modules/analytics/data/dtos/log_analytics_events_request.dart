import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/core/modules/analytics/data/dtos/analytics_event_dto.dart';

part 'log_analytics_events_request.g.dart';

@JsonSerializable(createFactory: false, explicitToJson: true)
class LogAnalyticsEventsRequest {
  const LogAnalyticsEventsRequest({required this.events});

  @JsonKey(name: 'p_events')
  final List<AnalyticsEventDto> events;

  Map<String, dynamic> toJson() => _$LogAnalyticsEventsRequestToJson(this);
}
