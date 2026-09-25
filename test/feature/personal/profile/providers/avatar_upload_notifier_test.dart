import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/update_user_avatar.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:typed_result/typed_result.dart';

class _FakeUserProfileNotifier extends UserProfileNotifier {
  @override
  Future<UserProfile?> build() async => UserProfile(
    userId: 'u1',
    name: 'n',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    avatarPath: 'u1/avatar/old.jpg',
  );
}

class _SucceedingUpdateUserAvatar implements UpdateUserAvatar {
  @override
  Future<Result<void, Failure>> call(final UpdateUserAvatarParams params) async =>
      const Ok(null);

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  test('a failed avatar reload does not turn a saved upload into a failure', () async {
    final container = ProviderContainer(
      retry: (final _, final _) => null,
      overrides: [
        userProfileProvider.overrideWith(_FakeUserProfileNotifier.new),
        updateUserAvatarUseCaseProvider.overrideWithValue(_SucceedingUpdateUserAvatar()),
        avatarFileProvider.overrideWith((final ref) async => throw const NetworkFailure()),
      ],
    );
    addTearDown(container.dispose);
    container.listen(avatarUploadProvider, (final _, final _) {});
    container.listen(avatarFileProvider, (final _, final _) {});

    final result = await container.read(avatarUploadProvider.notifier).upload(File('a.jpg'));

    expect(result.isSuccess, isTrue);
    expect(container.read(avatarUploadProvider).hasError, isFalse);
  });
}
