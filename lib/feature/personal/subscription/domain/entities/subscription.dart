import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/config/app_constants.dart';

part 'subscription.freezed.dart';

@freezed
sealed class Subscription with _$Subscription {
  const factory Subscription({required final String userId, required final String plan}) =
      _Subscription;
  const Subscription._();

  bool get isMax => plan == AppConstants.planMax;
  bool get isPro => plan == AppConstants.planPro;
  bool get isFree => plan == AppConstants.planFree;

  bool get requiresWatermark => isFree;
}
