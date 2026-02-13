import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/shared/measurements/entities/body_measurements.dart';

part 'user_profile.freezed.dart';

@freezed
sealed class UserProfile with _$UserProfile {
  const factory UserProfile({
    required final String userId,
    required final String name,
    required final BodyMeasurements measurements,
    final String? avatarPath,
    final String? email,
  }) = _UserProfile;
}
