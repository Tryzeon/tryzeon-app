import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/age_range.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile_update.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:typed_result/typed_result.dart';

part 'update_user_profile.freezed.dart';

/// A null field is left unchanged.
@freezed
sealed class UpdateUserProfileParams with _$UpdateUserProfileParams {
  const factory UpdateUserProfileParams({
    required final String name,
    final Gender? gender,
    final AgeRange? ageRange,
  }) = _UpdateUserProfileParams;
}

class UpdateUserProfile {
  UpdateUserProfile(this._repository);

  final UserProfileRepository _repository;

  Future<Result<UserProfile, Failure>> call(
    final UpdateUserProfileParams params,
  ) {
    return _repository.updateUserProfile(
      UserProfileUpdate(
        name: params.name,
        gender: params.gender,
        ageRange: params.ageRange,
      ),
    );
  }
}
