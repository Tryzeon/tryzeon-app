import 'package:json_annotation/json_annotation.dart';

part 'product_analytics_summary_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ProductAnalyticsSummaryModel {
  const ProductAnalyticsSummaryModel({
    required this.storeId,
    required this.productId,
    required this.year,
    required this.month,
    required this.viewCount,
    required this.tryonCount,
    required this.purchaseClickCount,
  });

  factory ProductAnalyticsSummaryModel.fromJson(final Map<String, dynamic> json) =>
      _$ProductAnalyticsSummaryModelFromJson(json);

  final String storeId;
  final String productId;
  final int year;
  final int month;
  final int viewCount;
  final int tryonCount;
  final int purchaseClickCount;

  Map<String, dynamic> toJson() => _$ProductAnalyticsSummaryModelToJson(this);
}
