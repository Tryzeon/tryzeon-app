import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/feature/personal/onboarding/domain/usecases/complete_onboarding.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';

part 'personal_onboarding_providers.g.dart';

@riverpod
CompleteOnboarding completeOnboardingUseCase(final Ref ref) {
  return CompleteOnboarding(ref.watch(userProfileRepositoryProvider));
}
