import 'dart:io';
import 'dart:typed_data';

import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/core/domain/services/cache_service.dart';
import 'package:tryzeon/feature/store/data/mappers/store_mappr.dart';
import 'package:tryzeon/feature/store/profile/data/collections/store_profile_collection.dart';
import 'package:tryzeon/feature/store/profile/data/models/store_profile_model.dart';

class StoreProfileLocalDataSource {
  StoreProfileLocalDataSource(this._isarService, this._cacheService);

  final IsarService _isarService;
  final CacheService _cacheService;
  static const _mappr = StoreMappr();

  Future<StoreProfileModel?> getStoreProfile() async {
    final isar = await _isarService.db;
    final collection = await isar.storeProfileCollections.where().findFirst();
    if (collection == null) return null;

    if (collection.lastUpdated == null ||
        DateTime.now().difference(collection.lastUpdated!) >
            AppConstants.staleDurationStoreProfile) {
      return null;
    }

    final model = _mappr.convert<StoreProfileCollection, StoreProfileModel>(collection);
    return model;
  }

  Future<void> saveStoreProfile(final StoreProfileModel profile) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.storeProfileCollections.clear();
      final collection = _mappr.convert<StoreProfileModel, StoreProfileCollection>(
        profile,
      );
      collection.lastUpdated = DateTime.now();
      await isar.storeProfileCollections.put(collection);
    });
  }

  Future<File?> getLogo(final String path) {
    return _cacheService.getImage(path);
  }

  Future<File?> downloadLogo(final String path, final String downloadUrl) {
    return _cacheService.getImage(path, downloadUrl: downloadUrl);
  }

  Future<void> saveLogo(final Uint8List bytes, final String path) {
    return _cacheService.saveImage(bytes, path);
  }

  Future<void> deleteLogo(final String path) {
    return _cacheService.deleteImage(path);
  }
}
