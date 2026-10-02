import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';

void main() {
  test('offers the preset matching the gender picked at onboarding', () {
    expect(PresetAvatar.forGender(Gender.female), [PresetAvatar.female]);
    expect(PresetAvatar.forGender(Gender.male), [PresetAvatar.male]);
  });

  test('offers every preset when the gender is unknown', () {
    expect(PresetAvatar.forGender(null), PresetAvatar.values);
  });
}
