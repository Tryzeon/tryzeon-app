import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/age_range.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:typed_result/typed_result.dart';

part 'complete_onboarding.freezed.dart';

/// A null field is left unchanged.
@freezed
sealed class CompleteOnboardingParams with _$CompleteOnboardingParams {
  const factory CompleteOnboardingParams({
    final Gender? gender,
    final AgeRange? ageRange,
    final List<ClothingStyle>? stylePreferences,
  }) = _CompleteOnboardingParams;
}

class CompleteOnboarding {
  CompleteOnboarding(this._repository);

  final UserProfileRepository _repository;

  Future<Result<void, Failure>> call(final CompleteOnboardingParams params) {
    return _repository.completeUserOnboarding(
      gender: params.gender,
      ageRange: params.ageRange,
      stylePreferences: params.stylePreferences,
    );
  }
}
