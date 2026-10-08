import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/data/collections/cache_entry.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/error/exceptions.dart';

import '../../../support/isar_test_harness.dart';

void main() {
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  test('remove turns a stored entry into a miss', () async {
    final harness = await openTestIsar();
    addTearDown(harness.dispose);
    final dataSource = CacheEntryLocalDataSource(harness.service);
    await dataSource.markHasData('k');

    await dataSource.remove('k');

    expect(await dataSource.getEntryStatus('k'), isNull);
  });

  test('an undecodable stored status throws CacheDecodeException', () async {
    final harness = await openTestIsar();
    addTearDown(harness.dispose);
    final dataSource = CacheEntryLocalDataSource(harness.service);
    final isar = await harness.service.db;
    await isar.writeTxn(() async {
      await isar.cacheEntrys.putByCacheKey(
        CacheEntry()
          ..cacheKey = 'k'
          ..status = 'absent'
          ..fetchedAt = DateTime.now(),
      );
    });

    await expectLater(
      dataSource.getEntryStatus('k'),
      throwsA(isA<CacheDecodeException>()),
    );
  });
}
