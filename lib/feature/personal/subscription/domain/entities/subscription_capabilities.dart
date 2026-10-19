import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_capabilities.freezed.dart';

@freezed
sealed class SubscriptionCapabilities with _$SubscriptionCapabilities {
  const factory SubscriptionCapabilities({required final int wardrobeLimit}) =
      _SubscriptionCapabilities;
}
