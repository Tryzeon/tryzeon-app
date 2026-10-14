import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/tutorial/domain/usecases/complete_tutorial.dart';

part 'tutorial_providers.g.dart';

@riverpod
CompleteTutorial completeTutorialUseCase(final Ref ref) {
  return CompleteTutorial(ref.watch(userProfileRepositoryProvider));
}
