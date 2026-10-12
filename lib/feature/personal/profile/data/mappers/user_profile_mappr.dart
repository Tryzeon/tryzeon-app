import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/feature/common/body_measurements/data/mappers/body_measurements_mappr.dart';
import 'package:tryzeon/feature/common/clothing_style/data/mappers/clothing_style_cache_converters.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/personal/profile/data/collections/user_profile_cache.dart';
import 'package:tryzeon/feature/personal/profile/data/dtos/update_user_profile_request.dart';
import 'package:tryzeon/feature/personal/profile/data/dtos/user_profile_dto.dart';
import 'package:tryzeon/feature/personal/profile/data/mappers/profile_cache_converters.dart';
import 'package:tryzeon/feature/personal/profile/data/mappers/user_profile_mappr.auto_mappr.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/age_range.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile_update.dart';

@AutoMappr(
  [
    MapType<UserProfileDto, UserProfile>(),
    MapType<UserProfileUpdate, UpdateUserProfileRequest>(),
    MapType<UserProfile, UserProfileCache>(
      converters: [
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
