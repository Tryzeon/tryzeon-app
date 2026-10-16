import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:tryzeon/feature/personal/profile/domain/services/avatar_storage.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/select_preset_avatar.dart';
import 'package:typed_result/typed_result.dart';

UserProfile _profile(final Avatar? avatar) => UserProfile(
  userId: 'u1',
  isTutorialCompleted: true,
  name: 'n',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  avatar: avatar,
);

class _FakeRepository implements UserProfileRepository {
  Result<UserProfile, Failure> profileResult = Ok(
    _profile(const Avatar.uploaded('u1/avatar/old.jpg')),
  );
  Result<void, Failure> updateResult = const Ok(null);
  final List<Avatar> saved = [];

  final List<bool> profileReads = [];

  @override
  Future<Result<UserProfile, Failure>> getUserProfile({
    final bool forceRefresh = false,
  }) async {
    profileReads.add(forceRefresh);
    return profileResult;
  }

  @override
  Future<Result<void, Failure>> updateAvatar(final Avatar avatar) async {
    saved.add(avatar);
    return updateResult;
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeAvatarStorage implements AvatarStorage {
  Result<void, Failure> deleteResult = const Ok(null);
  final List<String> deleted = [];

  @override
  Future<Result<String, Failure>> upload(final File image) =>
      throw UnimplementedError('a preset is never uploaded');

  @override
  Future<Result<void, Failure>> delete(final String path) async {
    deleted.add(path);
    return deleteResult;
  }
}

void main() {
  late _FakeRepository repository;
  late _FakeAvatarStorage storage;
  late SelectPresetAvatar selectPresetAvatar;

  setUp(() {
    repository = _FakeRepository();
    storage = _FakeAvatarStorage();
    selectPresetAvatar = SelectPresetAvatar(
      repository: repository,
      avatarStorage: storage,
    );
  });

  test(
    'reads the previous avatar from the server, so a change made in LIFF is not missed',
    () async {
      await selectPresetAvatar(PresetAvatar.female);

      expect(repository.profileReads, [true]);
    },
  );

  test(
    'points the profile at the preset, then deletes the previous photo',
    () async {
      final result = await selectPresetAvatar(PresetAvatar.female);

      expect(result.isSuccess, isTrue);
      expect(repository.saved, [const Avatar.preset(PresetAvatar.female)]);
      expect(storage.deleted, ['u1/avatar/old.jpg']);
    },
  );

  test('switching from another preset deletes nothing', () async {
    repository.profileResult = Ok(
      _profile(const Avatar.preset(PresetAvatar.male)),
    );

    final result = await selectPresetAvatar(PresetAvatar.female);

    expect(result.isSuccess, isTrue);
    expect(repository.saved, [const Avatar.preset(PresetAvatar.female)]);
    expect(storage.deleted, isEmpty);
  });

  test('a first avatar deletes nothing', () async {
    repository.profileResult = Ok(_profile(null));

    final result = await selectPresetAvatar(PresetAvatar.female);

    expect(result.isSuccess, isTrue);
    expect(storage.deleted, isEmpty);
  });

  test('a failed write keeps the previous photo', () async {
    repository.updateResult = const Err(ServerFailure());

    final result = await selectPresetAvatar(PresetAvatar.female);

    expect(result.getError(), const ServerFailure());
    expect(storage.deleted, isEmpty);
  });

  test('an unreadable profile writes nothing', () async {
    repository.profileResult = const Err(NetworkFailure());

    final result = await selectPresetAvatar(PresetAvatar.female);

    expect(result.getError(), const NetworkFailure());
    expect(repository.saved, isEmpty);
  });

  test(
    'a previous photo that cannot be deleted does not fail the switch',
    () async {
      storage.deleteResult = const Err(NetworkFailure());

      final result = await selectPresetAvatar(PresetAvatar.female);

      expect(result.isSuccess, isTrue);
    },
  );
}
