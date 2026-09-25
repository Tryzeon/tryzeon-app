import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:tryzeon/feature/personal/profile/domain/services/avatar_storage.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/update_user_avatar.dart';
import 'package:typed_result/typed_result.dart';

class _FakeRepository implements UserProfileRepository {
  Result<void, Failure> updateResult = const Ok(null);
  String? savedPath;

  @override
  Future<Result<void, Failure>> updateAvatarPath(final String path) async {
    savedPath = path;
    return updateResult;
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeAvatarStorage implements AvatarStorage {
  Result<String, Failure> uploadResult = const Ok('u1/avatar/new.jpg');
  final List<String> deleted = [];

  @override
  Future<Result<String, Failure>> upload(final File image) async => uploadResult;

  @override
  Future<Result<void, Failure>> delete(final String path) async {
    deleted.add(path);
    return const Ok(null);
  }
}

void main() {
  late _FakeRepository repository;
  late _FakeAvatarStorage storage;
  late UpdateUserAvatar updateUserAvatar;

  final params = UpdateUserAvatarParams(
    avatarFile: File('a.jpg'),
    previousAvatarPath: 'u1/avatar/old.jpg',
  );

  setUp(() {
    repository = _FakeRepository();
    storage = _FakeAvatarStorage();
    updateUserAvatar = UpdateUserAvatar(repository: repository, avatarStorage: storage);
  });

  test('points the profile at the new avatar, then deletes the old one', () async {
    final result = await updateUserAvatar(params);

    expect(result.isSuccess, isTrue);
    expect(repository.savedPath, 'u1/avatar/new.jpg');
    expect(storage.deleted, ['u1/avatar/old.jpg']);
  });

  test('a failed write discards the new avatar', () async {
    repository.updateResult = const Err(ServerFailure());

    await updateUserAvatar(params);

    expect(storage.deleted, ['u1/avatar/new.jpg']);
  });

  test('a failed upload never writes the profile', () async {
    storage.uploadResult = const Err(NetworkFailure());

    final result = await updateUserAvatar(params);

    expect(result.getError(), const NetworkFailure());
    expect(repository.savedPath, isNull);
  });
}
