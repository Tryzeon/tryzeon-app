import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/personal/profile/data/dtos/user_profile_dto.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';

Map<String, dynamic> _row({final bool withTutorialFlag = true}) => {
  'user_id': 'u1',
  'name': 'Eric',
  'created_at': '2026-01-01T00:00:00Z',
  'updated_at': '2026-01-01T00:00:00Z',
  'is_onboarded': true,
  if (withTutorialFlag) 'is_tutorial_completed': false,
};

void main() {
  test('decodes is_tutorial_completed', () {
    expect(UserProfileDto.fromJson(_row()).isTutorialCompleted, isFalse);
  });

  test('a row without is_tutorial_completed fails instead of defaulting', () {
    expect(
      () => UserProfileDto.fromJson(_row(withTutorialFlag: false)),
      throwsA(isA<TypeError>()),
    );
  });

  test('decodes avatar_preset by its wire name', () {
    expect(
      UserProfileDto.fromJson({
        ..._row(),
        'avatar_preset': 'male',
      }).avatarPreset,
      PresetAvatar.male,
    );
  });

  test('a preset this client does not know decodes as no preset', () {
    expect(
      UserProfileDto.fromJson({
        ..._row(),
        'avatar_preset': 'female_2',
      }).avatarPreset,
      isNull,
    );
  });
}
