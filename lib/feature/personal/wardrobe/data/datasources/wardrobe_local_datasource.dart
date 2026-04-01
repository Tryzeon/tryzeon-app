import 'dart:io';
import 'dart:typed_data';

import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/core/domain/services/cache_service.dart';
import 'package:tryzeon/feature/personal/data/mappers/personal_mappr.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/collections/wardrobe_item_collection.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/models/wardrobe_item_model.dart';

class WardrobeLocalDataSource {
  WardrobeLocalDataSource(
    this._isarService,
    this._cacheService,
    this._cacheEntryLocalDataSource,
  );

  final IsarService _isarService;
  final CacheService _cacheService;
  final CacheEntryLocalDataSource _cacheEntryLocalDataSource;
  static const _mappr = PersonalMappr();
  static const cacheKey = 'wardrobe_items';

  Future<CacheLookup<List<WardrobeItemModel>>> getWardrobeItems() async {
    final isar = await _isarService.db;
    final cacheStatus = await _cacheEntryLocalDataSource.getEntryStatus(cacheKey);
    if (cacheStatus == null) return const CacheMiss();

    if (cacheStatus == CacheEntryStatus.empty) {
      return const CacheEmpty();
    }

    final collections = await isar.wardrobeItemCollections
        .where()
        .sortByCreatedAtDesc()
        .findAll();

    if (collections.isEmpty) return const CacheMiss();

    final models = _mappr.convertList<WardrobeItemCollection, WardrobeItemModel>(
      collections,
    );
    return CacheHit(models);
  }

  Future<void> saveWardrobeItems(final List<WardrobeItemModel> items) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.wardrobeItemCollections.clear();
      final collections = _mappr.convertList<WardrobeItemModel, WardrobeItemCollection>(
        items,
      );
      await isar.wardrobeItemCollections.putAll(collections);
    });
    await _cacheEntryLocalDataSource.markListState(cacheKey, isEmpty: items.isEmpty);
  }

  Future<void> saveWardrobeItem(final WardrobeItemModel item) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      final collection = _mappr.convert<WardrobeItemModel, WardrobeItemCollection>(item);
      await isar.wardrobeItemCollections.put(collection);
    });
    await _cacheEntryLocalDataSource.markListState(cacheKey, isEmpty: false);
  }

  Future<void> deleteWardrobeItem(final String id) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.wardrobeItemCollections.deleteByItemId(id);
    });

    if (await isar.wardrobeItemCollections.count() == 0) {
      await _cacheEntryLocalDataSource.markListState(cacheKey, isEmpty: true);
    } else {
      await _cacheEntryLocalDataSource.markListState(cacheKey, isEmpty: false);
    }
  }

  Future<void> saveImage(final Uint8List bytes, final String path) {
    return _cacheService.saveImage(bytes, path);
  }

  Future<File?> getImage(final String path, {final String? downloadUrl}) {
    return _cacheService.getImage(path, downloadUrl: downloadUrl);
  }

  Future<void> deleteImage(final String path) {
    return _cacheService.deleteImage(path);
  }
}
