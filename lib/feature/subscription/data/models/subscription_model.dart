import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/subscription/domain/entities/subscription.dart';

part 'subscription_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class SubscriptionModel {
  const SubscriptionModel({required this.userId, required this.plan});

  factory SubscriptionModel.fromJson(final Map<String, dynamic> json) =>
      _$SubscriptionModelFromJson(json);

  final String userId;
  final SubscriptionPlan plan;

  Map<String, dynamic> toJson() => _$SubscriptionModelToJson(this);

  Subscription toEntity() {
    return Subscription(userId: userId, plan: plan);
  }
}
