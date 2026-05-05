import 'package:json_annotation/json_annotation.dart';

part 'subscription_plan_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class SubscriptionPlanModel {
  const SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.wardrobeLimit,
    required this.tryonLimit,
    required this.videoLimit,
    required this.chatLimit,
    required this.sortOrder,
    required this.isActive,
  });

  factory SubscriptionPlanModel.fromJson(final Map<String, dynamic> json) =>
      _$SubscriptionPlanModelFromJson(json);

  final String id;
  final String name;
  final int wardrobeLimit;
  final int tryonLimit;
  final int videoLimit;
  final int chatLimit;
  final int sortOrder;
  final bool isActive;

  Map<String, dynamic> toJson() => _$SubscriptionPlanModelToJson(this);
}
