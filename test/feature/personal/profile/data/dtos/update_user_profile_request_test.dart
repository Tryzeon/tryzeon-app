import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/body_measurements/data/dtos/body_measurements_dto.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/personal/profile/data/dtos/update_user_profile_request.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/age_range.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';

void main() {
  test('sends only the fields being changed', () {
    expect(const UpdateUserProfileRequest(name: 'Eric').toJson(), {
      'name': 'Eric',
    });
    expect(const UpdateUserProfileRequest(avatarPath: 'u1/a.jpg').toJson(), {
      'avatar_path': 'u1/a.jpg',
    });
  });

  test('encodes enums by their wire value', () {
    expect(
      const UpdateUserProfileRequest(
        gender: Gender.female,
        ageRange: AgeRange.age25to34,
        stylePreferences: [ClothingStyle.korean, ClothingStyle.streetwear],
        isOnboarded: true,
      ).toJson(),
      {
        'gender': 'female',
        'age_range': '25_34',
        'style_preferences': ['korean', 'streetwear'],
        'is_onboarded': true,
      },
    );
  });

  test('encodes measurements as a nested json object', () {
    expect(
      const UpdateUserProfileRequest(
        measurements: BodyMeasurementsDto(height: 170, waist: 70),
      ).toJson(),
      {
        'measurements': {'height': 170.0, 'waist': 70.0},
      },
    );
  });

  test('encodes the tutorial flag', () {
    expect(const UpdateUserProfileRequest(isTutorialCompleted: true).toJson(), {
      'is_tutorial_completed': true,
    });
  });
}
