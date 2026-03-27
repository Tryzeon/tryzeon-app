import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_capabilities.freezed.dart';

@freezed
sealed class SubscriptionCapabilities with _$SubscriptionCapabilities {
  const factory SubscriptionCapabilities({
    required bool requiresWatermark,
    required bool hasVideoAccess,
    required int wardrobeLimit,
  }) = _SubscriptionCapabilities;
}
