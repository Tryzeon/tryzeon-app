import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/feature/personal/subscription/data/datasources/subscription_capabilities_local_datasource.dart';
import 'package:tryzeon/feature/personal/subscription/domain/entities/subscription_capabilities.dart';

import '../../../../../support/isar_test_harness.dart';

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

  SubscriptionCapabilitiesLocalDataSource build() =>
      SubscriptionCapabilitiesLocalDataSource(
        harness.service,
        CacheEntryLocalDataSource(harness.service),
      );

  const pro = SubscriptionCapabilities(
    wardrobeLimit: 100,
    dailyTryonLimit: 20,
    dailyChatLimit: 50,
    dailyVideoLimit: 3,
  );
  const free = SubscriptionCapabilities(
    wardrobeLimit: 10,
    dailyTryonLimit: 2,
    dailyChatLimit: 5,
    dailyVideoLimit: 0,
  );

  test('each tier reads back only its own capabilities', () async {
    final local = build();

    await local.saveTierCapabilities(AppSubscriptionTier.pro, pro);
    await local.saveTierCapabilities(AppSubscriptionTier.free, free);

    expect(
      (await local.getTierCapabilities(AppSubscriptionTier.pro)
              as CacheHit<SubscriptionCapabilities>)
          .data,
      pro,
    );
    expect(
      (await local.getTierCapabilities(AppSubscriptionTier.free)
              as CacheHit<SubscriptionCapabilities>)
          .data,
      free,
    );
    expect(
      await local.getTierCapabilities(AppSubscriptionTier.max),
      isA<CacheMiss<SubscriptionCapabilities>>(),
    );
  });

  test('video access follows the daily video limit', () {
    expect(pro.hasVideoAccess, isTrue);
    expect(free.hasVideoAccess, isFalse);
  });
}
