import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';

enum PresetAvatar {
  female,
  male;

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
