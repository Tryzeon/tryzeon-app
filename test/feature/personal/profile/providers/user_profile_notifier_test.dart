import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile_update.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/update_user_profile.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/upload_user_avatar.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:typed_result/typed_result.dart';

UserProfile _profile({
  final String name = 'n',
  final bool isTutorialCompleted = false,
  final Avatar? avatar,
}) => UserProfile(
  userId: 'u1',
  name: name,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  avatar: avatar,
  isOnboarded: true,
  isTutorialCompleted: isTutorialCompleted,
);

class _FakeRepository implements UserProfileRepository {
  var loads = 0;
  Result<UserProfile, Failure>? updateResult;

  @override
  Future<Result<UserProfile, Failure>> getUserProfile({
    final bool forceRefresh = false,
  }) async {
    loads++;
    return Ok(_profile());
  }

  @override
  Future<Result<UserProfile, Failure>> updateUserProfile(
    final UserProfileUpdate update,
  ) async =>
      updateResult ??
      Ok(
        _profile(
          name: update.name ?? 'n',
          isTutorialCompleted: update.isTutorialCompleted ?? false,
        ),
      );

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeUploadUserAvatar implements UploadUserAvatar {
  @override
  Future<Result<UserProfile, Failure>> call(final File avatarFile) async =>
      Ok(_profile(avatar: const Avatar.uploaded('u1/avatar/new.jpg')));

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  late ProviderContainer container;
  late _FakeRepository repository;

  setUp(() async {
    repository = _FakeRepository();
    container = ProviderContainer(
      overrides: [
        isAuthenticatedProvider.overrideWithValue(true),
        userProfileRepositoryProvider.overrideWithValue(repository),
        uploadUserAvatarUseCaseProvider.overrideWithValue(
          _FakeUploadUserAvatar(),
        ),
      ],
      retry: (final _, final _) => null,
    );
    addTearDown(container.dispose);
    container.listen(userProfileProvider, (final _, final _) {});
    await container.read(userProfileProvider.future);
  });

  UserProfileNotifier owner() => container.read(userProfileProvider.notifier);

  test('updateProfile shows the saved profile without refetching', () async {
    final result = await owner().updateProfile(
      UpdateUserProfileParams(original: _profile(), name: 'renamed'),
    );

    expect(result.get()!.name, 'renamed');
    expect(container.read(userProfileProvider).value!.name, 'renamed');
    expect(repository.loads, 1);
  });

  test('a failed write keeps the current profile', () async {
    repository.updateResult = const Err(NetworkFailure());

    final result = await owner().updateProfile(
      UpdateUserProfileParams(original: _profile(), name: 'renamed'),
    );

    expect(result.getError(), isA<NetworkFailure>());
    expect(container.read(userProfileProvider).value!.name, 'n');
  });

  test('completeTutorial updates an unlistened owner', () async {
    final unlistened = ProviderContainer(
      overrides: [
        isAuthenticatedProvider.overrideWithValue(true),
        userProfileRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(unlistened.dispose);
    await unlistened.read(userProfileProvider.future);

    await unlistened.read(userProfileProvider.notifier).completeTutorial();

    expect(
      unlistened.read(userProfileProvider).value!.isTutorialCompleted,
      isTrue,
    );
  });

  test('uploadAvatar shows the new avatar', () async {
    await owner().uploadAvatar(File('me.jpg'));

    expect(
      container.read(userProfileProvider).value!.avatar,
      const Avatar.uploaded('u1/avatar/new.jpg'),
    );
  });
}
