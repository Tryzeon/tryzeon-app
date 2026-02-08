import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/config/app_constants.dart';

part 'subscription.freezed.dart';

enum SubscriptionPlan {
  free,
  pro,
  max;

  String get displayName {
    switch (this) {
      case SubscriptionPlan.free:
        return '免費版 Free';
      case SubscriptionPlan.pro:
        return '專業版 Pro';
      case SubscriptionPlan.max:
        return '尊爵版 Max';
    }
  }

  int get wardrobeLimit {
    switch (this) {
      case SubscriptionPlan.free:
        return AppConstants.wardrobeLimitFree;
      case SubscriptionPlan.pro:
        return AppConstants.wardrobeLimitPro;
      case SubscriptionPlan.max:
        return AppConstants.wardrobeLimitMax;
    }
  }
}

@freezed
sealed class Subscription with _$Subscription {
  const factory Subscription({
    required final String userId,
    required final SubscriptionPlan plan,
  }) = _Subscription;
}
