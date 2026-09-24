import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';

part 'subscription_tier_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class SubscriptionTierDto {
  const SubscriptionTierDto({
    required this.id,
    required this.wardrobeLimit,
    required this.tryonLimit,
    required this.videoLimit,
    required this.chatLimit,
  });

  factory SubscriptionTierDto.fromJson(final Map<String, dynamic> json) =>
      _$SubscriptionTierDtoFromJson(json);

  final AppSubscriptionTier id;
  final int wardrobeLimit;
  final int tryonLimit;
  final int videoLimit;
  final int chatLimit;

  Map<String, dynamic> toJson() => _$SubscriptionTierDtoToJson(this);
}
