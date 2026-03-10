import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_plan_info.freezed.dart';

@freezed
sealed class SubscriptionPlanInfo with _$SubscriptionPlanInfo {
  const factory SubscriptionPlanInfo({
    required final String id,
    required final String name,
    required final int price,
    required final int wardrobeLimit,
    required final int tryonLimit,
    required final int sortOrder,
    required final bool isActive,
  }) = _SubscriptionPlanInfo;
}
