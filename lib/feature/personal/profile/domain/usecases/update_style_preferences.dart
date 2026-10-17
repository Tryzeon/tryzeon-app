import 'package:collection/collection.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile_update.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:typed_result/typed_result.dart';

class UpdateStylePreferences {
  UpdateStylePreferences(this._repository);

  final UserProfileRepository _repository;

  /// The selection is a set, so a reordering alone writes nothing.
  Future<Result<UserProfile, Failure>> call({
    required final UserProfile original,
    required final List<ClothingStyle> stylePreferences,
  }) async {
    final unchanged = const SetEquality<ClothingStyle>().equals(
      stylePreferences.toSet(),
      (original.stylePreferences ?? const <ClothingStyle>[]).toSet(),
    );
    if (unchanged) return Ok(original);
    return _repository.updateUserProfile(
      UserProfileUpdate(stylePreferences: stylePreferences),
    );
  }
}
