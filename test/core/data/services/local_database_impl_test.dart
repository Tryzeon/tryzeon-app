import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/data/services/local_database_impl.dart';

import '../../../support/isar_test_harness.dart';

void main() {
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  test(
    'clear wipes every collection, including other features cache entries',
    () async {
      final harness = await openTestIsar();
      addTearDown(harness.dispose);
      final cacheEntryDataSource = CacheEntryLocalDataSource(harness.service);
      await cacheEntryDataSource.markHasData('k');

      await LocalDatabaseImpl(harness.service).clear();

      expect(await cacheEntryDataSource.getEntryStatus('k'), isNull);
    },
  );
}
