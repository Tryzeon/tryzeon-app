import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/data/services/image_file_cache.dart';
import 'package:tryzeon/core/data/services/local_data_store_impl.dart';

import '../../../support/isar_test_harness.dart';

class _FakeImageFileCache implements ImageFileCache {
  _FakeImageFileCache({this.error});

  final Object? error;
  int clears = 0;

  @override
  Future<void> clear() async {
    clears++;
    if (error case final error?) throw error;
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  test(
    'clear wipes every collection, including other features cache entries',
    () async {
      final harness = await openTestIsar();
      addTearDown(harness.dispose);
      final cacheEntryDataSource = CacheEntryLocalDataSource(harness.service);
      await cacheEntryDataSource.markHasData('k');
      final imageFileCache = _FakeImageFileCache();

      final result = await LocalDataStoreImpl(
        harness.service,
        imageFileCache,
      ).clear();

      expect(result.isSuccess, isTrue);
      expect(await cacheEntryDataSource.getEntryStatus('k'), isNull);
      expect(imageFileCache.clears, 1);
    },
  );

  test(
    'a broken image cache still wipes the database and reports the failure',
    () async {
      final harness = await openTestIsar();
      addTearDown(harness.dispose);
      final cacheEntryDataSource = CacheEntryLocalDataSource(harness.service);
      await cacheEntryDataSource.markHasData('k');

      final result = await LocalDataStoreImpl(
        harness.service,
        _FakeImageFileCache(error: Exception('disk')),
      ).clear();

      expect(result.isFailure, isTrue);
      expect(await cacheEntryDataSource.getEntryStatus('k'), isNull);
    },
  );
}
