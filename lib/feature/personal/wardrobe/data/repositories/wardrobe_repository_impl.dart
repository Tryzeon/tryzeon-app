import 'dart:io';

import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/data/mappers/personal_mappr.dart';
import 'package:typed_result/typed_result.dart';

import '../../domain/entities/wardrobe_item.dart';
import '../../domain/repositories/wardrobe_repository.dart';
import '../datasources/wardrobe_local_datasource.dart';
import '../datasources/wardrobe_remote_datasource.dart';
import '../dtos/create_wardrobe_item_request.dart';
import '../dtos/update_wardrobe_item_request.dart';
import '../dtos/wardrobe_item_dto.dart';

class WardrobeRepositoryImpl implements WardrobeRepository {
  WardrobeRepositoryImpl({
    required final WardrobeRemoteDataSource remoteDataSource,
    required final WardrobeLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final WardrobeRemoteDataSource _remoteDataSource;
  final WardrobeLocalDataSource _localDataSource;
  static const _mappr = PersonalMappr();

  @override
  Future<Result<List<WardrobeItem>, Failure>> getWardrobeItems({
    final bool forceRefresh = false,
  }) async {
    try {
      // 1. Try Local Cache
      if (!forceRefresh) {
        try {
          final cachedItems = await _localDataSource.getWardrobeItems();
          switch (cachedItems) {
            case CacheHit<List<WardrobeItem>>(:final data):
              return Ok(data);
            case CacheEmpty<List<WardrobeItem>>():
              return const Ok([]);
            case CacheMiss<List<WardrobeItem>>():
              break;
          }
        } catch (e, stackTrace) {
          AppLogger.warning(
            'Local cache read failed, falling back to remote',
            e,
            stackTrace,
          );
        }
      }

      // 2. Try Remote
      final remoteItems = await _remoteDataSource.getWardrobeItems();
      final items = _mappr.convertList<WardrobeItemDto, WardrobeItem>(remoteItems);

      // 3. Update Cache
      try {
        await _localDataSource.saveWardrobeItems(items);
      } catch (e, stackTrace) {
        AppLogger.warning('Failed to save wardrobe items to cache', e, stackTrace);
      }

      return Ok(items);
    } catch (e, stackTrace) {
      AppLogger.error('Wardrobe fetch failed', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> createWardrobeItem({
    required final String id,
    required final String imagePath,
    required final GarmentType garmentType,
    required final List<String> tags,
  }) async {
    try {
      await _remoteDataSource.createWardrobeItem(
        CreateWardrobeItemRequest(
          id: id,
          imagePath: imagePath,
          garmentType: garmentType,
          tags: tags,
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create wardrobe item', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }

    try {
      await _localDataSource.saveWardrobeItems(
        _mappr.convertList<WardrobeItemDto, WardrobeItem>(
          await _remoteDataSource.getWardrobeItems(),
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.warning('Wardrobe refresh failed, invalidating cache', e, stackTrace);
      try {
        await _localDataSource.invalidateWardrobeItems();
      } catch (e, stackTrace) {
        AppLogger.error('Failed to invalidate wardrobe cache', e, stackTrace);
      }
    }
    return const Ok(null);
  }

  @override
  Future<Result<void, Failure>> deleteWardrobeItem(final String id) async {
    try {
      await _remoteDataSource.deleteWardrobeItem(id);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete wardrobe item', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }

    try {
      await _localDataSource.deleteWardrobeItem(id);
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Failed to evict deleted wardrobe item from cache',
        e,
        stackTrace,
      );
    }
    return const Ok(null);
  }

  @override
  Future<Result<WardrobeItem, Failure>> updateWardrobeItem({
    required final String id,
    final GarmentType? garmentType,
    final List<String>? tags,
  }) async {
    try {
      final updatedItem = _mappr.convert<WardrobeItemDto, WardrobeItem>(
        await _remoteDataSource.updateWardrobeItem(
          id: id,
          request: UpdateWardrobeItemRequest(garmentType: garmentType, tags: tags),
        ),
      );
      await _localDataSource.saveWardrobeItem(updatedItem);
      return Ok(updatedItem);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update wardrobe item', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<File, Failure>> getWardrobeItemImage(final String imagePath) async {
    try {
      final cachedImage = await _localDataSource.getImage(imagePath);
      if (cachedImage != null) return Ok(cachedImage);

      final url = await _remoteDataSource.createSignedUrl(imagePath);
      final image = await _localDataSource.getImage(imagePath, downloadUrl: url);

      if (image == null) {
        return const Err(UnknownFailure('Failed to retrieve wardrobe image'));
      }

      return Ok(image);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load wardrobe images', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
