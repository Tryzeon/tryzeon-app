import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/config/app_constants.dart';

part 'app_subscription_entitlement.freezed.dart';

@JsonEnum(valueField: 'value')
enum AppSubscriptionTier {
  free(AppConstants.entitlementFreeId),
  pro(AppConstants.entitlementProId),
  max(AppConstants.entitlementMaxId);

  const AppSubscriptionTier(this.value);
  final String value;

  static AppSubscriptionTier? tryFromString(final String? value) =>
      AppSubscriptionTier.values.where((final e) => e.value == value).firstOrNull;
}

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
