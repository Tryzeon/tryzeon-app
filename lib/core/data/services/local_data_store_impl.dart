import 'package:tryzeon/core/data/services/image_file_cache.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/core/domain/services/local_data_store.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:typed_result/typed_result.dart';

class LocalDataStoreImpl implements LocalDataStore {
  LocalDataStoreImpl(this._isarService, this._imageFileCache);

  final IsarService _isarService;
  final ImageFileCache _imageFileCache;

  /// Both stores are cleared even when one fails, so a broken image cache
  /// never leaves the previous user's rows behind.
  @override
  Future<Result<void, Failure>> clear() async {
    Failure? failure;

    try {
      final isar = await _isarService.db;
      await isar.writeTxn(() async {
        await isar.clear();
      });
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear local database', e, stackTrace);
      failure = mapExceptionToFailure(e);
    }

    try {
      await _imageFileCache.clear();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear image file cache', e, stackTrace);
      failure ??= mapExceptionToFailure(e);
    }

    return failure == null ? const Ok(null) : Err(failure);
  }
}
