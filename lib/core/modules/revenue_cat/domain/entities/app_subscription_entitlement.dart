import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_subscription_entitlement.freezed.dart';

@freezed
sealed class AppSubscriptionEntitlement with _$AppSubscriptionEntitlement {
  const factory AppSubscriptionEntitlement({
    required final bool isProActive,
    required final bool isMaxActive,
    required final String? expirationDate,
    required final String? productIdentifier,
  }) = _AppSubscriptionEntitlement;

  const AppSubscriptionEntitlement._();

  bool get hasActiveSubscription => isProActive || isMaxActive;

  bool get isFree => !hasActiveSubscription;
}
