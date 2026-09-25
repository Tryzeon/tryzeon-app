import 'dart:io';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/profile/data/datasources/user_profile_local_datasource.dart';
import 'package:tryzeon/feature/personal/profile/data/datasources/user_profile_remote_datasource.dart';
import 'package:tryzeon/feature/personal/profile/domain/services/avatar_storage.dart';
import 'package:typed_result/typed_result.dart';

class AvatarStorageImpl implements AvatarStorage {
  AvatarStorageImpl(this._remoteDataSource, this._localDataSource);

  final UserProfileRemoteDataSource _remoteDataSource;
  final UserProfileLocalDataSource _localDataSource;

  @override
  Future<Result<String, Failure>> upload(final File image) async {
    final String path;
    try {
      path = await _remoteDataSource.uploadAvatar(image);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to upload avatar', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }

    try {
      await _localDataSource.saveAvatar(await image.readAsBytes(), path);
    } catch (e, stackTrace) {
      AppLogger.warning('Failed to cache uploaded avatar', e, stackTrace);
    }
    return Ok(path);
  }

  @override
  Future<Result<void, Failure>> delete(final String path) async {
    try {
      await _remoteDataSource.deleteAvatar(path);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete avatar', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }

    try {
      await _localDataSource.deleteAvatar(path);
    } catch (e, stackTrace) {
      AppLogger.warning('Failed to evict cached avatar', e, stackTrace);
    }
    return const Ok(null);
  }
}
