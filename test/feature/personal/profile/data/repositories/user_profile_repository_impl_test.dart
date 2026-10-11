import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/data/collections/cache_entry.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/data/services/image_file_cache.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/body_measurements/domain/entities/body_measurements.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/personal/profile/data/collections/user_profile_cache.dart';
import 'package:tryzeon/feature/personal/profile/data/datasources/user_profile_local_datasource.dart';
import 'package:tryzeon/feature/personal/profile/data/datasources/user_profile_remote_datasource.dart';
import 'package:tryzeon/feature/personal/profile/data/dtos/update_user_profile_request.dart';
import 'package:tryzeon/feature/personal/profile/data/dtos/user_profile_dto.dart';
import 'package:tryzeon/feature/personal/profile/data/repositories/user_profile_repository_impl.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/age_range.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile_update.dart';
import 'package:typed_result/typed_result.dart';

import '../../../../../support/isar_test_harness.dart';

class _FakeRemote implements UserProfileRemoteDataSource {
  _FakeRemote(this.profile);

  final UserProfileDto profile;
  int calls = 0;
  final List<Map<String, dynamic>> updates = [];
  Object? getError;
  Object? updateError;

  @override
  Future<UserProfileDto> getUserProfile() async {
    calls++;
    if (getError case final error?) throw error;
    return profile;
  }

  @override
  Future<void> updateUserProfile(final UpdateUserProfileRequest request) async {
    updates.add(request.toJson());
    if (updateError case final error?) throw error;
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _NoopImageFileCache implements ImageFileCache {
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

  Future<void> seedCache({
    final String? gender = 'female',
    final String? ageRange = '25_34',
    final List<String>? stylePreferences = const ['korean'],
  }) => harness.isar.writeTxn(() async {
    await harness.isar.userProfileCaches.putByUserId(
      UserProfileCache()
        ..userId = 'u1'
        ..name = 'Eric'
        ..createdAt = DateTime(2026)
        ..updatedAt = DateTime(2026)
        ..gender = gender
        ..ageRange = ageRange
        ..stylePreferences = stylePreferences
        ..isOnboarded = true,
    );
    await harness.isar.cacheEntrys.putByCacheKey(
      CacheEntry()
        ..cacheKey = UserProfileLocalDataSource.cacheKey
        ..status = CacheEntryStatus.hasData.name
        ..fetchedAt = DateTime.now(),
    );
  });

  final remoteProfile = UserProfileDto(
    userId: 'u1',
    name: 'Eric',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    gender: Gender.female,
    ageRange: AgeRange.age25to34,
    stylePreferences: const [ClothingStyle.korean],
    isOnboarded: true,
  );

  UserProfileRepositoryImpl buildRepository(final _FakeRemote remote) =>
      UserProfileRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: UserProfileLocalDataSource(
          harness.service,
          _NoopImageFileCache(),
          CacheEntryLocalDataSource(harness.service),
        ),
      );

  test('re-fetches when a cached age range no longer decodes', () async {
    await seedCache(ageRange: '18_25');

    final remote = _FakeRemote(remoteProfile);
    final profile = (await buildRepository(remote).getUserProfile()).get()!;

    expect(remote.calls, 1);
    expect(profile.ageRange, AgeRange.age25to34);

    final cached = await harness.isar.userProfileCaches.getByUserId('u1');
    expect(cached!.ageRange, '25_34');
  });

  test('re-fetches when a cached style preference no longer decodes', () async {
    await seedCache(stylePreferences: const ['korean', 'y2k']);

    final remote = _FakeRemote(remoteProfile);
    final profile = (await buildRepository(remote).getUserProfile()).get()!;

    expect(remote.calls, 1);
    expect(profile.stylePreferences, [ClothingStyle.korean]);

    final cached = await harness.isar.userProfileCaches.getByUserId('u1');
    expect(cached!.stylePreferences, ['korean']);
  });

  test('re-fetches when a cached gender no longer decodes', () async {
    await seedCache(gender: 'nonbinary');

    final remote = _FakeRemote(remoteProfile);
    final profile = (await buildRepository(remote).getUserProfile()).get()!;

    expect(remote.calls, 1);
    expect(profile.gender, Gender.female);
  });

  test('serves the cache untouched when every cached value decodes', () async {
    await seedCache();

    final remote = _FakeRemote(remoteProfile);
    final profile = (await buildRepository(remote).getUserProfile()).get()!;

    expect(remote.calls, 0);
    expect(profile.gender, Gender.female);
    expect(profile.ageRange, AgeRange.age25to34);
    expect(profile.stylePreferences, [ClothingStyle.korean]);
  });

  test(
    'null cached enums stay null instead of counting as undecodable',
    () async {
      await seedCache(gender: null, ageRange: null, stylePreferences: null);

      final remote = _FakeRemote(remoteProfile);
      final profile = (await buildRepository(remote).getUserProfile()).get()!;

      expect(remote.calls, 0);
      expect(profile.gender, isNull);
      expect(profile.ageRange, isNull);
      expect(profile.stylePreferences, isNull);
    },
  );

  test(
    'updateUserProfile succeeds and drops the cache when the refresh fails',
    () async {
      await seedCache();
      final remote = _FakeRemote(remoteProfile)
        ..getError = const SocketException('offline');

      final result = await buildRepository(remote).updateUserProfile(
        const UserProfileUpdate(avatarPath: 'u1/avatar/new.jpg'),
      );

      expect(result.isSuccess, isTrue);
      expect(
        await CacheEntryLocalDataSource(
          harness.service,
        ).getEntryStatus(UserProfileLocalDataSource.cacheKey),
        isNull,
      );
      expect(await harness.isar.userProfileCaches.count(), 0);
    },
  );

  test(
    'updateUserProfile returns not-found and skips the refresh when no row matched',
    () async {
      final remote = _FakeRemote(remoteProfile)
        ..updateError = const PostgrestException(
          message: 'no rows',
          code: 'PGRST116',
        );

      final result = await buildRepository(remote).updateUserProfile(
        const UserProfileUpdate(avatarPath: 'u1/avatar/new.jpg'),
      );

      expect(result.getError(), const NotFoundFailure());
      expect(remote.calls, 0);
    },
  );

  test(
    'updateUserProfile sends only the changed fields and caches the refetched row',
    () async {
      await seedCache();
      final remote = _FakeRemote(remoteProfile);

      final result = await buildRepository(remote).updateUserProfile(
        const UserProfileUpdate(
          measurements: BodyMeasurements(height: 170),
          isOnboarded: true,
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(remote.updates, [
        {
          'measurements': {'height': 170.0},
          'is_onboarded': true,
        },
      ]);
      expect(remote.calls, 1);
      expect(await harness.isar.userProfileCaches.count(), 1);
    },
  );
}
