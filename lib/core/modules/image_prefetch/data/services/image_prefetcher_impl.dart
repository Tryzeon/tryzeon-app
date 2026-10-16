import 'package:collection/collection.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:tryzeon/core/data/errors/map_exception_to_failure.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/image_prefetch/domain/services/image_prefetcher.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:typed_result/typed_result.dart';

class ImagePrefetcherImpl implements ImagePrefetcher {
  ImagePrefetcherImpl(this._cacheManager);

  final BaseCacheManager _cacheManager;

  @override
  Future<Result<void, Failure>> prefetch(final Iterable<String> urls) async {
    final failures = await Future.wait(urls.toSet().map(_fetch));
    final failure = failures.nonNulls.firstOrNull;
    return failure == null ? const Ok(null) : Err(failure);
  }

  Future<Failure?> _fetch(final String url) async {
    try {
      await _cacheManager.getSingleFile(url);
      return null;
    } catch (e, stackTrace) {
      AppLogger.warning('Failed to prefetch image $url', e, stackTrace);
      return mapExceptionToFailure(e);
    }
  }
}
