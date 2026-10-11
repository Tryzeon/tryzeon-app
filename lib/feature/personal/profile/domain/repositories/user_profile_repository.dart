import 'dart:io';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile_update.dart';
import 'package:typed_result/typed_result.dart';

abstract class UserProfileRepository {
  Future<Result<UserProfile, Failure>> getUserProfile({
    final bool forceRefresh = false,
  });

  Future<Result<File, Failure>> getUserAvatar(final String path);

  Future<Result<void, Failure>> updateUserProfile(
    final UserProfileUpdate update,
  );
}
