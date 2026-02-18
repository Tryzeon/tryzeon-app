import 'package:json_annotation/json_annotation.dart';

part 'store_analytics_summary_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class StoreAnalyticsSummaryModel {
  const StoreAnalyticsSummaryModel({
    required this.storeId,
    required this.year,
    required this.month,
    required this.viewCount,
    required this.tryonCount,
    required this.purchaseClickCount,
  });

  factory StoreAnalyticsSummaryModel.fromJson(final Map<String, dynamic> json) =>
      _$StoreAnalyticsSummaryModelFromJson(json);

  final String storeId;
  final int year;
  final int month;
  final int viewCount;
  final int tryonCount;
  final int purchaseClickCount;

  Map<String, dynamic> toJson() => _$StoreAnalyticsSummaryModelToJson(this);
}
