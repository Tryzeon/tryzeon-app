import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/personal/onboarding/providers/onboarding_notifier.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/age_range.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/complete_onboarding.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:typed_result/typed_result.dart';

UserProfile _profile({final bool isOnboarded = false}) => UserProfile(
  userId: 'u1',
  name: 'n',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  isOnboarded: isOnboarded,
  isTutorialCompleted: false,
);

class _FakeProfile extends UserProfileNotifier {
  @override
  Future<UserProfile?> build() async => _profile();
}

class _FakeCompleteOnboarding implements CompleteOnboarding {
  CompleteOnboardingParams? received;

  @override
  Future<Result<UserProfile, Failure>> call(
    final CompleteOnboardingParams params,
  ) async {
    received = params;
    return Ok(_profile(isOnboarded: true));
  }
}

void main() {
  test('submits the answers straight to the usecase', () async {
    final completeOnboarding = _FakeCompleteOnboarding();
    final container = ProviderContainer(
      overrides: [
        userProfileProvider.overrideWith(_FakeProfile.new),
        completeOnboardingUseCaseProvider.overrideWithValue(completeOnboarding),
      ],
    );
    addTearDown(container.dispose);
    container.listen(userProfileProvider, (final _, final _) {});
    await container.read(userProfileProvider.future);
    final notifier = container.read(onboardingProvider.notifier)
      ..setGender(Gender.female)
      ..setAgeRange(AgeRange.age25to34)
      ..toggleStylePreference(ClothingStyle.korean);

    final result = await notifier.completeOnboarding();

    expect(result.isSuccess, isTrue);
    expect(
      completeOnboarding.received,
      const CompleteOnboardingParams(
        gender: Gender.female,
        ageRange: AgeRange.age25to34,
        stylePreferences: [ClothingStyle.korean],
      ),
    );
    expect(container.read(onboardingProvider).isSubmitting, isFalse);
    expect(container.read(userProfileProvider).value!.isOnboarded, isTrue);
  });
}
