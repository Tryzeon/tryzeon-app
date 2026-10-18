import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/data/collections/cache_entry.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/data/services/image_file_cache.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/body_measurements/domain/entities/body_measurements.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/personal/profile/data/collections/avatar_embedded.dart';
import 'package:tryzeon/feature/personal/profile/data/collections/user_profile_cache.dart';
import 'package:tryzeon/feature/personal/profile/data/datasources/user_profile_local_datasource.dart';
import 'package:tryzeon/feature/personal/profile/data/datasources/user_profile_remote_datasource.dart';
import 'package:tryzeon/feature/personal/profile/data/dtos/update_avatar_request.dart';
import 'package:tryzeon/feature/personal/profile/data/dtos/update_user_profile_request.dart';
import 'package:tryzeon/feature/personal/profile/data/dtos/user_profile_dto.dart';
import 'package:tryzeon/feature/personal/profile/data/repositories/user_profile_repository_impl.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/age_range.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile_update.dart';
import 'package:typed_result/typed_result.dart';

import '../../../../../support/isar_test_harness.dart';

class _FakeRemote implements UserProfileRemoteDataSource {
  _FakeRemote(this.profile);

  final UserProfileDto profile;
  int calls = 0;
  final List<Map<String, dynamic>> updates = [];
  final List<Map<String, dynamic>> avatarUpdates = [];
  Object? updateError;

  @override
  Future<UserProfileDto> getUserProfile() async {
    calls++;
    return profile;
  }

  @override
  Future<UserProfileDto> updateUserProfile(
    final UpdateUserProfileRequest request,
  ) async {
    updates.add(request.toJson());
    if (updateError case final error?) throw error;
    return profile;
  }

  @override
  Future<UserProfileDto> updateAvatar(final UpdateAvatarRequest request) async {
    avatarUpdates.add(request.toJson());
    if (updateError case final error?) throw error;
    return profile;
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _UnwritableLocal implements UserProfileLocalDataSource {
  var invalidated = false;

  @override
  Future<void> saveUserProfile(final UserProfile profile) async =>
      throw StateError('disk full');

  @override
  Future<void> invalidateUserProfile() async => invalidated = true;

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
    final AvatarEmbedded? avatar,
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
        ..avatar = avatar
        ..isOnboarded = true
        ..isTutorialCompleted = true,
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
    isTutorialCompleted: true,
    name: 'Eric',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    gender: Gender.female,
    ageRange: AgeRange.age25to34,
    stylePreferences: const [ClothingStyle.korean],
    avatarPreset: PresetAvatar.male,
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
    expect(profile.stylePreferences, {ClothingStyle.korean});

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

  test('re-fetches when a cached preset avatar no longer decodes', () async {
    await seedCache(avatar: AvatarEmbedded()..preset = 'female_2');

    final remote = _FakeRemote(remoteProfile);
    final profile = (await buildRepository(remote).getUserProfile()).get()!;

    expect(remote.calls, 1);
    expect(profile.avatar, const Avatar.preset(PresetAvatar.male));

    final cached = await harness.isar.userProfileCaches.getByUserId('u1');
    expect(cached!.avatar?.preset, 'male');
  });

  test('serves the cache untouched when every cached value decodes', () async {
    await seedCache();

    final remote = _FakeRemote(remoteProfile);
    final profile = (await buildRepository(remote).getUserProfile()).get()!;

    expect(remote.calls, 0);
    expect(profile.gender, Gender.female);
    expect(profile.ageRange, AgeRange.age25to34);
    expect(profile.stylePreferences, {ClothingStyle.korean});
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
      expect(profile.stylePreferences, isEmpty);
    },
  );

  test(
    'updateUserProfile succeeds and drops the cache when caching the row fails',
    () async {
      final local = _UnwritableLocal();
      final repository = UserProfileRepositoryImpl(
        remoteDataSource: _FakeRemote(remoteProfile),
        localDataSource: local,
      );

      final result = await repository.updateUserProfile(
        const UserProfileUpdate(name: 'Amy'),
      );

      expect(result.isSuccess, isTrue);
      expect(local.invalidated, isTrue);
    },
  );

  test(
    'updateUserProfile returns not-found and leaves the cache when no row matched',
    () async {
      final remote = _FakeRemote(remoteProfile)
        ..updateError = const PostgrestException(
          message: 'no rows',
          code: 'PGRST116',
        );

      final result = await buildRepository(
        remote,
      ).updateUserProfile(const UserProfileUpdate(name: 'Amy'));

      expect(result.getError(), const NotFoundFailure());
      expect(await harness.isar.userProfileCaches.count(), 0);
    },
  );

  test(
    'updateUserProfile sends only the changed fields and caches the returned row without refetching',
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
      expect(remote.calls, 0);
      final cached = await harness.isar.userProfileCaches.getByUserId('u1');
      expect(cached!.avatar?.preset, 'male');
    },
  );

  test('updateUserProfile sends the tutorial flag', () async {
    await seedCache();
    final remote = _FakeRemote(remoteProfile);

    final result = await buildRepository(
      remote,
    ).updateUserProfile(const UserProfileUpdate(isTutorialCompleted: true));

    expect(result.isSuccess, isTrue);
    expect(remote.updates, [
      {'is_tutorial_completed': true},
    ]);
  });

  test(
    'updateAvatar to a preset clears the uploaded path and caches the returned row without refetching',
    () async {
      await seedCache();
      final remote = _FakeRemote(remoteProfile);

      final result = await buildRepository(
        remote,
      ).updateAvatar(const Avatar.preset(PresetAvatar.female));

      expect(result.isSuccess, isTrue);
      expect(remote.avatarUpdates, [
        {'avatar_path': null, 'avatar_preset': 'female'},
      ]);
      expect(remote.calls, 0);
      final cached = await harness.isar.userProfileCaches.getByUserId('u1');
      expect(cached!.avatar?.preset, 'male');
    },
  );

  test('updateAvatar to an uploaded photo clears the preset', () async {
    final remote = _FakeRemote(remoteProfile);

    await buildRepository(
      remote,
    ).updateAvatar(const Avatar.uploaded('u1/avatar/me.jpg'));

    expect(remote.avatarUpdates, [
      {'avatar_path': 'u1/avatar/me.jpg', 'avatar_preset': null},
    ]);
  });

  test('a rejected updateAvatar is a failure and leaves the cache', () async {
    await seedCache();
    final remote = _FakeRemote(remoteProfile)
      ..updateError = const PostgrestException(message: 'check violation');

    final result = await buildRepository(
      remote,
    ).updateAvatar(const Avatar.preset(PresetAvatar.male));

    expect(result.getError(), const ServerFailure());
    final cached = await harness.isar.userProfileCaches.getByUserId('u1');
    expect(cached!.avatar, isNull);
  });
}
