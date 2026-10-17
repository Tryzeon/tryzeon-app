import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/age_range.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile_update.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:typed_result/typed_result.dart';

part 'update_user_profile.freezed.dart';

/// [original] is the profile the form was filled from; only the fields that
/// differ from it are written. A null [gender] or [ageRange] is left unchanged.
@freezed
sealed class UpdateUserProfileParams with _$UpdateUserProfileParams {
  const factory UpdateUserProfileParams({
    required final UserProfile original,
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
  ) async {
    final original = params.original;
    final update = UserProfileUpdate(
      name: params.name == original.name ? null : params.name,
      gender: params.gender == original.gender ? null : params.gender,
      ageRange: params.ageRange == original.ageRange ? null : params.ageRange,
    );
    if (update == const UserProfileUpdate()) return Ok(original);
    return _repository.updateUserProfile(update);
  }
}
