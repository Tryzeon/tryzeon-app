import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/personal/profile/data/dtos/update_avatar_request.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';

void main() {
  test('a preset clears the uploaded photo path', () {
    expect(
      const UpdateAvatarRequest(
        avatarPath: null,
        avatarPreset: PresetAvatar.female,
      ).toJson(),
      {'avatar_path': null, 'avatar_preset': 'female'},
    );
  });

  test('an uploaded photo clears the preset', () {
    expect(
      const UpdateAvatarRequest(
        avatarPath: 'u1/avatar/me.jpg',
        avatarPreset: null,
      ).toJson(),
      {'avatar_path': 'u1/avatar/me.jpg', 'avatar_preset': null},
    );
  });
}
