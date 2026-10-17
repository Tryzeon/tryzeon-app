import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile_update.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:typed_result/typed_result.dart';

class CompleteTutorial {
  CompleteTutorial(this._repository);

  final UserProfileRepository _repository;

  Future<Result<UserProfile, Failure>> call() => _repository.updateUserProfile(
    const UserProfileUpdate(isTutorialCompleted: true),
  );
}
