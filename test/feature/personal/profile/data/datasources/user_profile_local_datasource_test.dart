import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/data/collections/cache_entry.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/core/domain/services/cache_service.dart';
import 'package:tryzeon/feature/common/body_measurements/domain/entities/body_measurements.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/personal/profile/data/collections/user_profile_cache.dart';
import 'package:tryzeon/feature/personal/profile/data/datasources/user_profile_local_datasource.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/age_range.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';

import '../../../../../support/isar_test_harness.dart';

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

  UserProfileLocalDataSource build() => UserProfileLocalDataSource(
    harness.service,
    _NoopCacheService(),
    CacheEntryLocalDataSource(harness.service),
  );

  test('reads back exactly the profile it saved', () async {
    final profile = UserProfile(
      userId: 'u1',
      name: 'Amy',
      email: 'amy@example.com',
      avatarPath: 'u1/avatar.jpg',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026, 5),
      measurements: const BodyMeasurements(
        height: 165,
        weight: 52,
        shoulder: 38,
        chest: 84,
        waist: 64,
        hips: 90,
        thigh: 52,
      ),
      gender: Gender.female,
      ageRange: AgeRange.age25to34,
      stylePreferences: const [ClothingStyle.korean, ClothingStyle.minimalist],
      isOnboarded: true,
    );
    final local = build();

    await local.saveUserProfile(profile);

    expect((await local.getUserProfile() as CacheHit<UserProfile>).data, profile);
  });

  test('a cached row without measurements reads back as empty measurements', () async {
    await harness.isar.writeTxn(() async {
      await harness.isar.userProfileCaches.put(
        UserProfileCache()
          ..userId = 'u1'
          ..name = 'Amy'
          ..createdAt = DateTime(2026)
          ..updatedAt = DateTime(2026)
          ..isOnboarded = false,
      );
      await harness.isar.cacheEntrys.putByCacheKey(
        CacheEntry()
          ..cacheKey = UserProfileLocalDataSource.cacheKey
          ..status = CacheEntryStatus.hasData.name
          ..fetchedAt = DateTime.now(),
      );
    });

    final profile = (await build().getUserProfile() as CacheHit<UserProfile>).data;

    expect(profile.measurements, const BodyMeasurements());
  });
}
