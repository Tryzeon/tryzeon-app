import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/domain/entities/analytics_event.dart';

part 'analytics_event_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class AnalyticsEventModel {
  const AnalyticsEventModel({
    required this.productId,
    required this.storeId,
    required this.eventType,
  });

  factory AnalyticsEventModel.fromEntity(final AnalyticsEvent entity) {
    return AnalyticsEventModel(
      productId: entity.productId,
      storeId: entity.storeId,
      eventType: entity.eventType,
    );
  }

  factory AnalyticsEventModel.fromJson(final Map<String, dynamic> json) =>
      _$AnalyticsEventModelFromJson(json);

  final String productId;
  final String storeId;
  final String eventType;

  Map<String, dynamic> toJson() => _$AnalyticsEventModelToJson(this);

  AnalyticsEvent toEntity() {
    return AnalyticsEvent(productId: productId, storeId: storeId, eventType: eventType);
  }
}
