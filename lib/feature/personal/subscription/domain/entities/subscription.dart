import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription.freezed.dart';

@freezed
sealed class Subscription with _$Subscription {
  const factory Subscription({required final String userId, required final String plan}) =
      _Subscription;
}
