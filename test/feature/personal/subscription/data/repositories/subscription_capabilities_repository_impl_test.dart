import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/data/collections/cache_entry.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/feature/personal/subscription/data/collections/subscription_tier_cache.dart';
import 'package:tryzeon/feature/personal/subscription/data/datasources/subscription_capabilities_local_datasource.dart';
import 'package:tryzeon/feature/personal/subscription/data/datasources/subscription_capabilities_remote_datasource.dart';
import 'package:tryzeon/feature/personal/subscription/data/dtos/subscription_tier_dto.dart';
import 'package:tryzeon/feature/personal/subscription/data/repositories/subscription_capabilities_repository_impl.dart';
import 'package:typed_result/typed_result.dart';

import '../../../../../support/isar_test_harness.dart';

class _FakeRemote implements SubscriptionCapabilitiesRemoteDataSource {
  _FakeRemote({this.error});

  final Object? error;
  int calls = 0;

  @override
  Future<SubscriptionTierDto> getTierCapabilities(
    final AppSubscriptionTier tier,
  ) async {
    calls++;
    if (error case final error?) throw error;
    return SubscriptionTierDto(id: tier, wardrobeLimit: 100);
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
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
        ..wardrobeLimit = 10,
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
  });

  test('an offline fetch is reported as a network failure', () async {
    final result = await buildRepository(
      _FakeRemote(error: const SocketException('offline')),
    ).getCapabilitiesForTier(AppSubscriptionTier.pro);

    expect(result.getError(), const NetworkFailure());
  });
}
