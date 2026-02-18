import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/config/app_constants.dart';

part 'subscription.freezed.dart';

enum SubscriptionPlan {
  free,
  pro,
  max;

  int get wardrobeLimit => switch (this) {
    SubscriptionPlan.free => AppConstants.wardrobeLimitFree,
    SubscriptionPlan.pro => AppConstants.wardrobeLimitPro,
    SubscriptionPlan.max => AppConstants.wardrobeLimitMax,
  };
}

@freezed
sealed class Subscription with _$Subscription {
  const factory Subscription({
    required final String userId,
    required final SubscriptionPlan plan,
  }) = _Subscription;
}
