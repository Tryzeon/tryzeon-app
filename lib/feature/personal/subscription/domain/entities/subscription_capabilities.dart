import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_capabilities.freezed.dart';

@freezed
sealed class SubscriptionCapabilities with _$SubscriptionCapabilities {
  const factory SubscriptionCapabilities({
    required final bool requiresWatermark,
    required final bool hasVideoAccess,
    required final int wardrobeLimit,
  }) = _SubscriptionCapabilities;
}
