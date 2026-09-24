import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';

part 'subscription_tier_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class SubscriptionTierModel {
  const SubscriptionTierModel({
    required this.id,
    required this.wardrobeLimit,
    required this.tryonLimit,
    required this.videoLimit,
    required this.chatLimit,
  });

  factory SubscriptionTierModel.fromJson(final Map<String, dynamic> json) =>
      _$SubscriptionTierModelFromJson(json);

  final AppSubscriptionTier id;
  final int wardrobeLimit;
  final int tryonLimit;
  final int videoLimit;
  final int chatLimit;

  Map<String, dynamic> toJson() => _$SubscriptionTierModelToJson(this);
}
