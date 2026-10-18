import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/personal/profile/data/collections/avatar_embedded.dart';
import 'package:tryzeon/feature/personal/profile/data/collections/user_profile_cache.dart';
import 'package:tryzeon/feature/personal/profile/data/dtos/update_user_profile_request.dart';
import 'package:tryzeon/feature/personal/profile/data/dtos/user_profile_dto.dart';
import 'package:tryzeon/feature/personal/profile/data/mappers/user_profile_mappr.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile_update.dart';

void main() {
  const mappr = UserProfileMappr();

  Avatar? avatarOfRow({final String? avatarPath, final String? avatarPreset}) =>
      mappr
          .convert<UserProfileDto, UserProfile>(
            UserProfileDto.fromJson({
              'user_id': 'u1',
              'name': 'Eric',
              'created_at': '2026-01-01T00:00:00Z',
              'updated_at': '2026-01-01T00:00:00Z',
              'is_tutorial_completed': true,
              'avatar_path': avatarPath,
              'avatar_preset': avatarPreset,
            }),
          )
          .avatar;

  UserProfile profileWith(final Avatar? avatar) => UserProfile(
    userId: 'u1',
    name: 'Eric',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    avatar: avatar,
    isOnboarded: true,
    isTutorialCompleted: true,
  );

  test('a row with a preset reads as that preset', () {
    expect(
      avatarOfRow(avatarPreset: 'female'),
      const Avatar.preset(PresetAvatar.female),
    );
  });

  test('a row with a photo path reads as an uploaded photo', () {
    expect(
      avatarOfRow(avatarPath: 'u1/avatar/me.jpg'),
      const Avatar.uploaded('u1/avatar/me.jpg'),
    );
  });

  test('a row with no source, a blank path or an unknown preset has no '
      'avatar', () {
    expect(avatarOfRow(), isNull);
    expect(avatarOfRow(avatarPath: ''), isNull);
    expect(avatarOfRow(avatarPreset: 'female_2'), isNull);
  });

  test('a preset is cached by its wire name and no path', () {
    final cached = mappr
        .convert<UserProfile, UserProfileCache>(
          profileWith(const Avatar.preset(PresetAvatar.male)),
        )
        .avatar!;

    expect(cached.preset, 'male');
    expect(cached.path, isNull);
  });

  test('an uploaded photo is cached by its path and no preset', () {
    final cached = mappr
        .convert<UserProfile, UserProfileCache>(
          profileWith(const Avatar.uploaded('u1/avatar/me.jpg')),
        )
        .avatar!;

    expect(cached.path, 'u1/avatar/me.jpg');
    expect(cached.preset, isNull);
  });

  for (final avatar in const [
    Avatar.preset(PresetAvatar.female),
    Avatar.uploaded('u1/avatar/me.jpg'),
    null,
  ]) {
    test('$avatar survives a round trip through the cache', () {
      final profile = profileWith(avatar);

      expect(
        mappr.convert<UserProfileCache, UserProfile>(
          mappr.convert<UserProfile, UserProfileCache>(profile),
        ),
        profile,
      );
    });
  }

  test('a cached preset this client no longer knows fails to decode', () {
    final cache = mappr.convert<UserProfile, UserProfileCache>(
      profileWith(null),
    )..avatar = (AvatarEmbedded()..preset = 'female_2');

    expect(
      () => mappr.convert<UserProfileCache, UserProfile>(cache),
      throwsA(isA<CacheDecodeException>()),
    );
  });

  test('style preferences are sent in catalogue order, whatever the pick '
      'order', () {
    final request = mappr.convert<UserProfileUpdate, UpdateUserProfileRequest>(
      const UserProfileUpdate(
        stylePreferences: {ClothingStyle.streetwear, ClothingStyle.japanese},
      ),
    );

    expect(request.stylePreferences, [
      ClothingStyle.japanese,
      ClothingStyle.streetwear,
    ]);
  });
}
