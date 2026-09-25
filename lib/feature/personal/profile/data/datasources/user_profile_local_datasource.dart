import 'dart:io';
import 'dart:typed_data';

import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/core/domain/services/image_file_cache.dart';
import 'package:tryzeon/feature/personal/data/mappers/personal_mappr.dart';
import 'package:tryzeon/feature/personal/profile/data/collections/user_profile_cache.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';

class UserProfileLocalDataSource {
  UserProfileLocalDataSource(
    this._isarService,
    this._imageFileCache,
    this._cacheEntryLocalDataSource,
  );
  final IsarService _isarService;
  final ImageFileCache _imageFileCache;
  final CacheEntryLocalDataSource _cacheEntryLocalDataSource;
  static const _mappr = PersonalMappr();
  static const cacheKey = 'user_profile';

  Future<CacheLookup<UserProfile>> getUserProfile() async {
    final isar = await _isarService.db;
    final cacheStatus = await _cacheEntryLocalDataSource.getEntryStatus(
      cacheKey,
      staleDuration: AppConstants.staleDurationUserProfile,
    );
    if (cacheStatus == null) return const CacheMiss();

    final collection = await isar.userProfileCaches.where().findFirst();
    if (collection == null) return const CacheMiss();

    return CacheHit(_mappr.convert<UserProfileCache, UserProfile>(collection));
  }

  Future<void> saveUserProfile(final UserProfile profile) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.userProfileCaches.clear();
      final collection = _mappr.convert<UserProfile, UserProfileCache>(profile);
      await isar.userProfileCaches.put(collection);
    });
    await _cacheEntryLocalDataSource.markHasData(cacheKey);
  }

  Future<void> invalidateUserProfile() async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.userProfileCaches.clear();
    });
    await _cacheEntryLocalDataSource.remove(cacheKey);
  }

  Future<File?> getAvatar(final String path) {
    return _imageFileCache.getImage(path);
  }

  Future<void> saveAvatar(final Uint8List bytes, final String path) {
    return _imageFileCache.saveImage(bytes, path);
  }

  Future<File?> downloadAvatar(final String path, final String downloadUrl) {
    return _imageFileCache.getImage(path, downloadUrl: downloadUrl);
  }

  Future<void> deleteAvatar(final String path) {
    return _imageFileCache.deleteImage(path);
  }
}
