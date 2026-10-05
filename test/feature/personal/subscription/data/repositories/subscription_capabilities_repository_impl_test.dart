import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/data/collections/cache_entry.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/feature/personal/subscription/data/collections/subscription_tier_cache.dart';
import 'package:tryzeon/feature/personal/subscription/data/datasources/subscription_capabilities_local_datasource.dart';
import 'package:tryzeon/feature/personal/subscription/data/datasources/subscription_capabilities_remote_datasource.dart';
import 'package:tryzeon/feature/personal/subscription/data/dtos/subscription_tier_dto.dart';
import 'package:tryzeon/feature/personal/subscription/data/repositories/subscription_capabilities_repository_impl.dart';
import 'package:typed_result/typed_result.dart';

import '../../../../../support/isar_test_harness.dart';

class _FakeRemote implements SubscriptionCapabilitiesRemoteDataSource {
  int calls = 0;

  @override
  Future<SubscriptionTierDto> getTierCapabilities(
    final AppSubscriptionTier tier,
  ) async {
    calls++;
    return SubscriptionTierDto(
      id: tier,
      wardrobeLimit: 100,
      tryonLimit: 20,
      videoLimit: 3,
      chatLimit: 50,
    );
  }

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

  Future<void> seedCache(final String tier) => harness.isar.writeTxn(() async {
    await harness.isar.subscriptionTierCaches.putByTier(
      SubscriptionTierCache()
        ..tier = tier
        ..wardrobeLimit = 10
        ..dailyTryonLimit = 2
        ..dailyVideoLimit = 0
        ..dailyChatLimit = 5,
    );
    await harness.isar.cacheEntrys.putByCacheKey(
      CacheEntry()
        ..cacheKey = SubscriptionCapabilitiesLocalDataSource.cacheKeyForTier(
          AppSubscriptionTier.pro,
        )
        ..status = CacheEntryStatus.hasData.name
        ..fetchedAt = DateTime.now(),
    );
  });

  SubscriptionCapabilitiesRepositoryImpl buildRepository(
    final _FakeRemote remote,
  ) => SubscriptionCapabilitiesRepositoryImpl(
    remoteDataSource: remote,
    localDataSource: SubscriptionCapabilitiesLocalDataSource(
      harness.service,
      CacheEntryLocalDataSource(harness.service),
    ),
  );

  test('a row stored under an unknown tier is never read back', () async {
    await seedCache('plus');

    final remote = _FakeRemote();
    final capabilities = (await buildRepository(
      remote,
    ).getCapabilitiesForTier(AppSubscriptionTier.pro)).get()!;

    expect(remote.calls, 1);
    expect(capabilities.wardrobeLimit, 100);

    final cached = await harness.isar.subscriptionTierCaches.getByTier('pro');
    expect(cached!.wardrobeLimit, 100);
  });

  test('serves the cache untouched when the cached tier decodes', () async {
    await seedCache('pro');

    final remote = _FakeRemote();
    final capabilities = (await buildRepository(
      remote,
    ).getCapabilitiesForTier(AppSubscriptionTier.pro)).get()!;

    expect(remote.calls, 0);
    expect(capabilities.wardrobeLimit, 10);
    expect(capabilities.hasVideoAccess, isFalse);
  });
}
