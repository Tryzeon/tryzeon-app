import 'dart:io';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:typed_result/typed_result.dart';

class GetUserAvatar {
  GetUserAvatar(this._repository);
  final UserProfileRepository _repository;

  Future<Result<File, Failure>> call(final String path) => _repository.getUserAvatar(path);
}
