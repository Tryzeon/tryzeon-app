import 'dart:io';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:typed_result/typed_result.dart';

abstract class UserProfileRepository {
  Future<Result<UserProfile, Failure>> getUserProfile({final bool forceRefresh = false});

  Future<Result<void, Failure>> updateUserProfile({
    required final UserProfile original,
    required final UserProfile target,
    final File? avatarFile,
  });

  Future<Result<File, Failure>> getUserAvatar(final String path);
}
