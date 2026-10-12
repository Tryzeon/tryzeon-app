import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/personal/onboarding/domain/usecases/complete_onboarding.dart';
import 'package:tryzeon/feature/personal/onboarding/providers/onboarding_notifier.dart';
import 'package:tryzeon/feature/personal/onboarding/providers/personal_onboarding_providers.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/age_range.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';
import 'package:typed_result/typed_result.dart';

class _FakeCompleteOnboarding implements CompleteOnboarding {
  CompleteOnboardingParams? received;

  @override
  Future<Result<void, Failure>> call(
    final CompleteOnboardingParams params,
  ) async {
    received = params;
    return const Ok(null);
  }
}

void main() {
  test('submits the answers straight to the usecase', () async {
    final completeOnboarding = _FakeCompleteOnboarding();
    final container = ProviderContainer(
      overrides: [
        completeOnboardingUseCaseProvider.overrideWithValue(completeOnboarding),
      ],
    );
    addTearDown(container.dispose);
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
  });
}
