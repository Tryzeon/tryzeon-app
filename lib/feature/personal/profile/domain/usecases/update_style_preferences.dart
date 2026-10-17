import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile_update.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:typed_result/typed_result.dart';

class UpdateStylePreferences {
  UpdateStylePreferences(this._repository);

  final UserProfileRepository _repository;

  Future<Result<UserProfile, Failure>> call({
    required final List<ClothingStyle> stylePreferences,
  }) {
    return _repository.updateUserProfile(
      UserProfileUpdate(stylePreferences: stylePreferences),
    );
  }
}
