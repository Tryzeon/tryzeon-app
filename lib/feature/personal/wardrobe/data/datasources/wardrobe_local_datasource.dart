import 'dart:io';
import 'dart:typed_data';

import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/core/domain/services/cache_service.dart';
import 'package:tryzeon/feature/personal/data/mappers/personal_mappr.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/collections/wardrobe_item_collection.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/models/wardrobe_item_model.dart';

class WardrobeLocalDataSource {
  WardrobeLocalDataSource(this._isarService, this._cacheService);
  final IsarService _isarService;
  final CacheService _cacheService;
  static const _mappr = PersonalMappr();

  Future<List<WardrobeItemModel>?> getWardrobeItems() async {
    final isar = await _isarService.db;
    final collections = await isar.wardrobeItemCollections
        .where()
        .sortByCreatedAtDesc()
        .findAll();

    if (collections.isEmpty) return null;

    final models = _mappr.convertList<WardrobeItemCollection, WardrobeItemModel>(
      collections,
    );
    return models;
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
  }

  Future<void> saveWardrobeItem(final WardrobeItemModel item) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      final collection = _mappr.convert<WardrobeItemModel, WardrobeItemCollection>(item);
      await isar.wardrobeItemCollections.put(collection);
    });
  }

  Future<void> deleteWardrobeItem(final String id) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.wardrobeItemCollections.deleteByItemId(id);
    });
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
