import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/store/analytics/data/collections/store_analytics_collection.dart';

part 'store_analytics_summary_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class StoreAnalyticsSummaryModel {
  const StoreAnalyticsSummaryModel({
    required this.viewCount,
    required this.tryonCount,
    required this.purchaseClickCount,
  });

  factory StoreAnalyticsSummaryModel.fromJson(final Map<String, dynamic> json) =>
      _$StoreAnalyticsSummaryModelFromJson(json);

  final int viewCount;
  final int tryonCount;
  final int purchaseClickCount;

  Map<String, dynamic> toJson() => _$StoreAnalyticsSummaryModelToJson(this);

  /// Manual mapper with extra parameters - preserved
  StoreAnalyticsCollection toCollection(
    final String storeId,
    final int year,
    final int month,
  ) {
    return StoreAnalyticsCollection()
      ..storeId = storeId
      ..year = year
      ..month = month
      ..totalViewCount = viewCount
      ..totalTryonCount = tryonCount
      ..totalPurchaseClickCount = purchaseClickCount;
  }
}
