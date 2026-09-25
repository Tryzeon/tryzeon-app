import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_order_contact.dart';
import 'package:tryzeon/feature/store/profile/data/collections/store_profile_cache.dart';
import 'package:tryzeon/feature/store/profile/data/datasources/store_profile_local_datasource.dart';
import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart';

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

  StoreProfileLocalDataSource build() => StoreProfileLocalDataSource(
    harness.service,
    CacheEntryLocalDataSource(harness.service),
  );

  final profile = StoreProfile(
    id: 's1',
    ownerId: 'o1',
    name: 'Shop',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026, 4),
    channels: {StoreChannel.online, StoreChannel.physical},
    slug: 'shop',
    address: '台北市',
    latitude: 25.03,
    longitude: 121.56,
    logoPath: 's1/logo.png',
    logoUrl: 'https://cdn/s1/logo.png',
    orderContacts: const [
      StoreOrderContact(type: OrderContactType.instagram, value: '@shop'),
      StoreOrderContact(type: OrderContactType.line, value: '@shopline'),
    ],
  );

  test('reads back exactly the profile it saved', () async {
    final local = build();

    await local.saveStoreProfile(profile);

    expect((await local.getStoreProfile() as CacheHit<StoreProfile>).data, profile);
  });

  test('channels are cached in declaration order', () async {
    await build().saveStoreProfile(profile);

    final cached = await harness.isar.storeProfileCaches.where().findFirst();

    expect(cached!.channels, ['physical', 'online']);
  });
}
