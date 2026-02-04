import 'package:equatable/equatable.dart';

class AnalyticsEvent extends Equatable {
  const AnalyticsEvent({
    required this.productId,
    required this.storeId,
    required this.eventType,
  });

  final String productId;
  final String storeId;
  final String eventType;

  @override
  List<Object?> get props => [productId, storeId, eventType];

  Map<String, dynamic> toJson() {
    return {'product_id': productId, 'store_id': storeId, 'event_type': eventType};
  }
}
