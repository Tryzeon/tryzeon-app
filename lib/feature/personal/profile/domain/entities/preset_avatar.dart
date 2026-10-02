import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';

enum PresetAvatar {
  female(AppConstants.presetAvatarFemale),
  male(AppConstants.presetAvatarMale);

  const PresetAvatar(this.assetPath);
  final String assetPath;

  static List<PresetAvatar> forGender(final Gender? gender) => switch (gender) {
    Gender.female => const [PresetAvatar.female],
    Gender.male => const [PresetAvatar.male],
    null => PresetAvatar.values,
  };

  String get label => switch (this) {
    PresetAvatar.female => '女性模特',
    PresetAvatar.male => '男性模特',
  };
}
