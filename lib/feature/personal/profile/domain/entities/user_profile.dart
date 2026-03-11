import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/shared/measurements/entities/measurements.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/age_range.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/style_preference.dart';

part 'user_profile.freezed.dart';

@freezed
sealed class UserProfile with _$UserProfile {
  const factory UserProfile({
    required final String userId,
    required final String name,
    final Measurements? measurements,
    final String? avatarPath,
    final String? email,
    final Gender? gender,
    final AgeRange? ageRange,
    final List<StylePreference>? stylePreferences,
    @Default(false) final bool isOnboarded,
  }) = _UserProfile;
}
