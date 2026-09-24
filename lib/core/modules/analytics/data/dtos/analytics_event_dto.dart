import 'package:freezed_annotation/freezed_annotation.dart';

part 'analytics_event_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class AnalyticsEventDto {
  const AnalyticsEventDto({
    required this.productId,
    required this.storeId,
    required this.eventType,
  });

  factory AnalyticsEventDto.fromJson(final Map<String, dynamic> json) =>
      _$AnalyticsEventDtoFromJson(json);

  final String productId;
  final String storeId;
  final String eventType;

  Map<String, dynamic> toJson() => _$AnalyticsEventDtoToJson(this);
}
