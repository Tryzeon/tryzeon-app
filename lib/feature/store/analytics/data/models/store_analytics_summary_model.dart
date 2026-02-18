import 'package:json_annotation/json_annotation.dart';

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
}
