import 'package:freezed_annotation/freezed_annotation.dart';

part 'wardrobe_capacity.freezed.dart';

@freezed
sealed class WardrobeCapacity with _$WardrobeCapacity {
  const factory WardrobeCapacity({
    required final int used,
    required final int limit,
  }) = _WardrobeCapacity;

  const WardrobeCapacity._();

  static const double _nearLimitRatio = 0.9;

  bool get isFull => used >= limit;

  bool get isNearLimit => used >= limit * _nearLimitRatio;

  double get usage => limit <= 0 ? 1 : (used / limit).clamp(0, 1);
}
