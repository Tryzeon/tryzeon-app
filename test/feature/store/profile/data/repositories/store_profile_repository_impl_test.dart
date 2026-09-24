import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/data/collections/cache_entry.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/domain/services/cache_service.dart';
import 'package:tryzeon/feature/common/store/data/collections/store_order_contact_embedded.dart';
import 'package:tryzeon/feature/common/store/data/models/store_order_contact_model.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_order_contact.dart';
import 'package:tryzeon/feature/store/profile/data/collections/store_profile_cache.dart';
import 'package:tryzeon/feature/store/profile/data/datasources/store_profile_local_datasource.dart';
import 'package:tryzeon/feature/store/profile/data/datasources/store_profile_remote_datasource.dart';
import 'package:tryzeon/feature/store/profile/data/models/store_profile_model.dart';
import 'package:tryzeon/feature/store/profile/data/repositories/store_profile_repository_impl.dart';
import 'package:typed_result/typed_result.dart';

import '../../../../../support/isar_test_harness.dart';

class _FakeRemote implements StoreProfileRemoteDataSource {
  _FakeRemote(this.profile);

  final StoreProfileModel profile;
  int calls = 0;

  @override
  Future<StoreProfileModel?> getStoreProfile() async {
    calls++;
    return profile;
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _NoopCacheService implements CacheService {
  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  late TestIsar harness;

  setUp(() async {
    harness = await openTestIsar();
  });

  tearDown(() async {
    await harness.dispose();
  });

  Future<void> seedCache({
    final List<String> channels = const ['physical'],
    final String contactType = 'line',
  }) => harness.isar.writeTxn(() async {
    await harness.isar.storeProfileCaches.putByStoreId(
      StoreProfileCache()
        ..storeId = 's1'
        ..ownerId = 'o1'
        ..name = '測試店家'
        ..channels = channels
        ..orderContacts = [
          StoreOrderContactEmbedded()
            ..type = contactType
            ..value = '@shop',
        ]
        ..createdAt = DateTime(2026)
        ..updatedAt = DateTime(2026),
    );
    await harness.isar.cacheEntrys.putByCacheKey(
      CacheEntry()
        ..cacheKey = StoreProfileLocalDataSource.cacheKey
        ..status = CacheEntryStatus.hasData.name
        ..fetchedAt = DateTime.now(),
    );
  });

  final remoteProfile = StoreProfileModel(
    id: 's1',
    ownerId: 'o1',
    name: '測試店家',
    channels: const [StoreChannel.physical],
    orderContacts: const [
      StoreOrderContactModel(type: OrderContactType.line, value: '@shop'),
    ],
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  StoreProfileRepositoryImpl buildRepository(final _FakeRemote remote) =>
      StoreProfileRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: StoreProfileLocalDataSource(
          harness.service,
          _NoopCacheService(),
          CacheEntryLocalDataSource(harness.service),
        ),
      );

  test('re-fetches when a cached order contact type no longer decodes', () async {
    await seedCache(contactType: 'line_oa');

    final remote = _FakeRemote(remoteProfile);
    final profile = (await buildRepository(remote).getStoreProfile()).get()!;

    expect(remote.calls, 1);
    expect(profile.orderContacts.single.type, OrderContactType.line);

    final cached = await harness.isar.storeProfileCaches.getByStoreId('s1');
    expect(cached!.orderContacts.single.type, 'line');
  });

  test('re-fetches when a cached channel no longer decodes', () async {
    await seedCache(channels: const ['physical', 'popup']);

    final remote = _FakeRemote(remoteProfile);
    final profile = (await buildRepository(remote).getStoreProfile()).get()!;

    expect(remote.calls, 1);
    expect(profile.channels, {StoreChannel.physical});

    final cached = await harness.isar.storeProfileCaches.getByStoreId('s1');
    expect(cached!.channels, ['physical']);
  });

  test('serves the cache untouched when every cached value decodes', () async {
    await seedCache();

    final remote = _FakeRemote(remoteProfile);
    final profile = (await buildRepository(remote).getStoreProfile()).get()!;

    expect(remote.calls, 0);
    expect(profile.channels, {StoreChannel.physical});
    expect(profile.orderContacts.single.type, OrderContactType.line);
  });
}
