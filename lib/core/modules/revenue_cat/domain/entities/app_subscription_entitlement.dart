import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_subscription_entitlement.freezed.dart';

enum AppSubscriptionTier { free, pro, max }

@freezed
sealed class AppSubscriptionEntitlement with _$AppSubscriptionEntitlement {
  const factory AppSubscriptionEntitlement({
    required final AppSubscriptionTier tier,
    required final String? expirationDate,
    required final String? productIdentifier,
  }) = _AppSubscriptionEntitlement;

  const AppSubscriptionEntitlement._();

  bool get hasActiveSubscription => tier != AppSubscriptionTier.free;

  bool get isFree => !hasActiveSubscription;
}
