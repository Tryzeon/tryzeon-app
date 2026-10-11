import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/personal/onboarding/domain/usecases/complete_onboarding.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/age_range.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile_update.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:typed_result/typed_result.dart';

class _FakeRepository implements UserProfileRepository {
  UserProfileUpdate? saved;

  @override
  Future<Result<void, Failure>> updateUserProfile(
    final UserProfileUpdate update,
  ) async {
    saved = update;
    return const Ok(null);
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  test('marks the profile onboarded alongside the answers', () async {
    final repository = _FakeRepository();

    await CompleteOnboarding(repository)(
      const CompleteOnboardingParams(
        gender: Gender.male,
        ageRange: AgeRange.age18to24,
        stylePreferences: [ClothingStyle.casual],
      ),
    );

    expect(
      repository.saved,
      const UserProfileUpdate(
        gender: Gender.male,
        ageRange: AgeRange.age18to24,
        stylePreferences: [ClothingStyle.casual],
        isOnboarded: true,
      ),
    );
  });
}
