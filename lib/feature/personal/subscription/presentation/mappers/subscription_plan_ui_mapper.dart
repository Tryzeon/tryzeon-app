import 'package:tryzeon/feature/personal/subscription/domain/entities/subscription.dart';

/// UI display name extension for [SubscriptionPlan] in Presentation Layer.
extension SubscriptionPlanDisplay on SubscriptionPlan {
  /// The localized display name for UI rendering.
  String get displayName => switch (this) {
    SubscriptionPlan.free => '免費版 Free',
    SubscriptionPlan.pro => '專業版 Pro',
    SubscriptionPlan.max => '尊爵版 Max',
  };
}
