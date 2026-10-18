import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/age_range.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile_update.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/complete_onboarding.dart';
import 'package:typed_result/typed_result.dart';

final _saved = UserProfile(
  userId: 'u1',
  name: 'n',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  isTutorialCompleted: true,
);

class _FakeRepository implements UserProfileRepository {
  UserProfileUpdate? saved;

  @override
  Future<Result<UserProfile, Failure>> updateUserProfile(
    final UserProfileUpdate update,
  ) async {
    saved = update;
    return Ok(_saved);
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
        stylePreferences: {ClothingStyle.casual},
      ),
    );

    expect(
      repository.saved,
      const UserProfileUpdate(
        gender: Gender.male,
        ageRange: AgeRange.age18to24,
        stylePreferences: {ClothingStyle.casual},
        isOnboarded: true,
      ),
    );
  });
}
