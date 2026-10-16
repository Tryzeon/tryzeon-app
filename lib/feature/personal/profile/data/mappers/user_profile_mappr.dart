import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/feature/common/body_measurements/data/mappers/body_measurements_mappr.dart';
import 'package:tryzeon/feature/common/clothing_style/data/mappers/clothing_style_cache_converters.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/personal/profile/data/collections/avatar_embedded.dart';
import 'package:tryzeon/feature/personal/profile/data/collections/user_profile_cache.dart';
import 'package:tryzeon/feature/personal/profile/data/dtos/update_avatar_request.dart';
import 'package:tryzeon/feature/personal/profile/data/dtos/update_user_profile_request.dart';
import 'package:tryzeon/feature/personal/profile/data/dtos/user_profile_dto.dart';
import 'package:tryzeon/feature/personal/profile/data/mappers/profile_cache_converters.dart';
import 'package:tryzeon/feature/personal/profile/data/mappers/user_profile_mappr.auto_mappr.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/age_range.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile_update.dart';

@AutoMappr(
  [
    MapType<UserProfileDto, UserProfile>(
      fields: [Field('avatar', custom: UserProfileMapprHelper.avatarFromDto)],
    ),
    MapType<UserProfileUpdate, UpdateUserProfileRequest>(),
    MapType<Avatar, UpdateAvatarRequest>(
      fields: [
        Field('avatarPath', custom: UserProfileMapprHelper.avatarPathToRequest),
        Field(
          'avatarPreset',
          custom: UserProfileMapprHelper.avatarPresetToRequest,
        ),
      ],
    ),
    MapType<UserProfile, UserProfileCache>(
      converters: [
        TypeConverter<Avatar?, AvatarEmbedded?>(
          ProfileCacheConverters.avatarToCache,
        ),
        TypeConverter<Gender?, String?>(ProfileCacheConverters.genderToCache),
        TypeConverter<AgeRange?, String?>(
          ProfileCacheConverters.ageRangeToCache,
        ),
        TypeConverter<List<ClothingStyle>?, List<String>?>(
          ClothingStyleCacheConverters.listToCache,
        ),
      ],
    ),
    MapType<UserProfileCache, UserProfile>(
      converters: [
        TypeConverter<AvatarEmbedded?, Avatar?>(
          ProfileCacheConverters.avatarFromCache,
        ),
        TypeConverter<String?, Gender?>(ProfileCacheConverters.genderFromCache),
        TypeConverter<String?, AgeRange?>(
          ProfileCacheConverters.ageRangeFromCache,
        ),
        TypeConverter<List<String>?, List<ClothingStyle>?>(
          ClothingStyleCacheConverters.listFromCache,
        ),
      ],
    ),
  ],
  includes: [BodyMeasurementsMappr()],
)
class UserProfileMappr extends $UserProfileMappr {
  const UserProfileMappr();
}

class UserProfileMapprHelper {
  static Avatar? avatarFromDto(final UserProfileDto source) {
    if (source.avatarPreset case final preset?) return Avatar.preset(preset);
    if (source.avatarPath case final path? when path.isNotEmpty) {
      return Avatar.uploaded(path);
    }
    return null;
  }

  static String? avatarPathToRequest(final Avatar source) => switch (source) {
    AvatarFromUpload(:final path) => path,
    AvatarFromPreset() => null,
  };

  static PresetAvatar? avatarPresetToRequest(final Avatar source) =>
      switch (source) {
        AvatarFromPreset(:final preset) => preset,
        AvatarFromUpload() => null,
      };
}
