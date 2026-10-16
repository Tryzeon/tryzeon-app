import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/get_user_avatar.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:typed_result/typed_result.dart';

class _FakeGetUserAvatar implements GetUserAvatar {
  Result<File, Failure> result = Ok(File('female.jpg'));
  final List<Avatar> calls = [];

  @override
  Future<Result<File, Failure>> call(final Avatar avatar) async {
    calls.add(avatar);
    return result;
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  late _FakeGetUserAvatar getUserAvatar;

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      retry: (final _, final _) => null,
      overrides: [
        getUserAvatarUseCaseProvider.overrideWithValue(getUserAvatar),
      ],
    );
    addTearDown(container.dispose);
    container.listen(
      presetAvatarFileProvider(PresetAvatar.female),
      (final _, final _) {},
    );
    return container;
  }

  setUp(() {
    getUserAvatar = _FakeGetUserAvatar();
  });

  test('serves the image of the preset it is asked for', () async {
    final container = makeContainer();

    final file = await container.read(
      presetAvatarFileProvider(PresetAvatar.female).future,
    );

    expect(file.path, 'female.jpg');
    expect(getUserAvatar.calls, [const Avatar.preset(PresetAvatar.female)]);
  });

  test('a preset image that cannot be fetched surfaces its failure', () async {
    getUserAvatar.result = const Err(NetworkFailure());
    final container = makeContainer();

    await expectLater(
      container.read(presetAvatarFileProvider(PresetAvatar.female).future),
      throwsA(const NetworkFailure()),
    );
  });
}
