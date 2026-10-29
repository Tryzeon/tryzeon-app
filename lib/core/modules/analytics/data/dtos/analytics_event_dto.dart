import 'package:freezed_annotation/freezed_annotation.dart';

part 'analytics_event_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class AnalyticsEventDto {
  const AnalyticsEventDto({
    required this.productId,
    required this.storeId,
    required this.eventType,
    this.colorId,
  });

  factory AnalyticsEventDto.fromJson(final Map<String, dynamic> json) =>
      _$AnalyticsEventDtoFromJson(json);

  final String productId;
  final String storeId;
  final String eventType;
  @JsonKey(includeIfNull: false)
  final String? colorId;

  Map<String, dynamic> toJson() => _$AnalyticsEventDtoToJson(this);
}
