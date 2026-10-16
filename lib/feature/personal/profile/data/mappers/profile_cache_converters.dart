import 'package:tryzeon/core/data/cache/decode_cached_enum.dart';
import 'package:tryzeon/feature/personal/profile/data/collections/avatar_embedded.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/age_range.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';

class ProfileCacheConverters {
  static String? genderToCache(final Gender? source) => source?.value;

  static Gender? genderFromCache(final String? source) =>
      decodeCachedEnumOrNull(source, Gender.tryFromString);

  static String? ageRangeToCache(final AgeRange? source) => source?.value;

  static AgeRange? ageRangeFromCache(final String? source) =>
      decodeCachedEnumOrNull(source, AgeRange.tryFromString);

  static AvatarEmbedded? avatarToCache(final Avatar? source) =>
      switch (source) {
        AvatarFromPreset(:final preset) =>
          AvatarEmbedded()..preset = preset.name,
        AvatarFromUpload(:final path) => AvatarEmbedded()..path = path,
        null => null,
      };

  static Avatar? avatarFromCache(final AvatarEmbedded? source) {
    if (source?.preset case final preset?) {
      return Avatar.preset(
        decodeCachedEnum(
          preset,
          (final value) => PresetAvatar.values.asNameMap()[value],
        ),
      );
    }
    if (source?.path case final path?) return Avatar.uploaded(path);
    return null;
  }
}
