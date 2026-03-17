import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/age_range.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:typed_result/typed_result.dart';

class CompleteOnboarding {
  CompleteOnboarding(this._repository);

  final UserProfileRepository _repository;

  Future<Result<void, Failure>> call({
    required final Gender gender,
    required final AgeRange ageRange,
    final List<ClothingStyle>? stylePreferences,
  }) async {
    final profileResult = await _repository.getUserProfile(forceRefresh: true);

    if (profileResult.isFailure) {
      return Err(profileResult.getError()!);
    }

    final original = profileResult.get()!;
    final target = original.copyWith(
      gender: gender,
      ageRange: ageRange,
      stylePreferences: stylePreferences,
      isOnboarded: true,
    );

    return _repository.updateUserProfile(original: original, target: target);
  }
}
