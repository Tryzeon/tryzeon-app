import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/common/body_measurements/domain/entities/body_measurements.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/age_range.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';

part 'user_profile_update.freezed.dart';

/// A null field is left unchanged.
@freezed
sealed class UserProfileUpdate with _$UserProfileUpdate {
  const factory UserProfileUpdate({
    final String? name,
    final Gender? gender,
    final AgeRange? ageRange,
    final BodyMeasurements? measurements,
    final Set<ClothingStyle>? stylePreferences,
    final bool? isOnboarded,
    final bool? isTutorialCompleted,
  }) = _UserProfileUpdate;
}
