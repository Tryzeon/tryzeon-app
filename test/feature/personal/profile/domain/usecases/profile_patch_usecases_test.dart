import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/body_measurements/domain/entities/body_measurements.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/age_range.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile_update.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/update_style_preferences.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/update_user_body_measurements.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/update_user_profile.dart';
import 'package:typed_result/typed_result.dart';

final _original = UserProfile(
  userId: 'u1',
  name: 'Mia',
  gender: Gender.female,
  ageRange: AgeRange.age25to34,
  measurements: const BodyMeasurements(height: 160, weight: 50),
  stylePreferences: const [ClothingStyle.korean, ClothingStyle.casual],
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  isTutorialCompleted: true,
);

class _FakeRepository implements UserProfileRepository {
  final updates = <UserProfileUpdate>[];

  @override
  Future<Result<UserProfile, Failure>> updateUserProfile(
    final UserProfileUpdate update,
  ) async {
    updates.add(update);
    return Ok(_original);
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  late _FakeRepository repository;

  setUp(() => repository = _FakeRepository());

  test('UpdateUserProfile sends only the fields that changed', () async {
    await UpdateUserProfile(repository)(
      UpdateUserProfileParams(
        original: _original,
        name: 'Mia',
        gender: Gender.male,
        ageRange: AgeRange.age25to34,
      ),
    );

    expect(repository.updates, [const UserProfileUpdate(gender: Gender.male)]);
  });

  test('UpdateUserProfile with nothing changed writes nothing', () async {
    final result = await UpdateUserProfile(repository)(
      UpdateUserProfileParams(
        original: _original,
        name: 'Mia',
        gender: Gender.female,
        ageRange: AgeRange.age25to34,
      ),
    );

    expect(result.get(), _original);
    expect(repository.updates, isEmpty);
  });

  test('UpdateUserBodyMeasurements sends changed measurements', () async {
    await UpdateUserBodyMeasurements(repository)(
      original: _original,
      measurements: const BodyMeasurements(height: 161, weight: 50),
    );

    expect(repository.updates, [
      const UserProfileUpdate(
        measurements: BodyMeasurements(height: 161, weight: 50),
      ),
    ]);
  });

  test(
    'UpdateUserBodyMeasurements with unchanged measurements writes nothing',
    () async {
      final result = await UpdateUserBodyMeasurements(repository)(
        original: _original,
        measurements: const BodyMeasurements(height: 160, weight: 50),
      );

      expect(result.get(), _original);
      expect(repository.updates, isEmpty);
    },
  );

  test(
    'UpdateStylePreferences ignores a reordered but equal selection',
    () async {
      final result = await UpdateStylePreferences(repository)(
        original: _original,
        stylePreferences: const [ClothingStyle.casual, ClothingStyle.korean],
      );

      expect(result.get(), _original);
      expect(repository.updates, isEmpty);
    },
  );

  test('UpdateStylePreferences sends a changed selection', () async {
    await UpdateStylePreferences(repository)(
      original: _original,
      stylePreferences: const [ClothingStyle.casual],
    );

    expect(repository.updates, [
      const UserProfileUpdate(stylePreferences: [ClothingStyle.casual]),
    ]);
  });
}
