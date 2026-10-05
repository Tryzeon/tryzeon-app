import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/preset_avatar.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/domain/usecases/prepare_preset_avatar.dart';
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

class _FakeUpdateUserAvatar implements UpdateUserAvatar {
  Completer<Result<void, Failure>>? pending;
  final List<File> calls = [];

  @override
  Future<Result<void, Failure>> call(final File avatarFile) {
    calls.add(avatarFile);
    return pending?.future ?? Future.value(const Ok(null));
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakePreparePresetAvatar implements PreparePresetAvatar {
  Result<File, Failure> result = Ok(File('preset_male.jpg'));
  final List<PresetAvatar> calls = [];

  @override
  Future<Result<File, Failure>> call(final PresetAvatar preset) async {
    calls.add(preset);
    return result;
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  late _FakeUpdateUserAvatar updateUserAvatar;
  late _FakePreparePresetAvatar preparePresetAvatar;

  ProviderContainer makeContainer({
    final Future<File?> Function(Ref ref)? avatarFile,
  }) {
    final container = ProviderContainer(
      retry: (final _, final _) => null,
      overrides: [
        userProfileProvider.overrideWith(_FakeUserProfileNotifier.new),
        updateUserAvatarUseCaseProvider.overrideWithValue(updateUserAvatar),
        preparePresetAvatarUseCaseProvider.overrideWithValue(
          preparePresetAvatar,
        ),
        avatarFileProvider.overrideWith(
          avatarFile ?? (final ref) async => null,
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(avatarUploadProvider, (final _, final _) {});
    container.listen(avatarFileProvider, (final _, final _) {});
    return container;
  }

  setUp(() {
    updateUserAvatar = _FakeUpdateUserAvatar();
    preparePresetAvatar = _FakePreparePresetAvatar();
  });

  test(
    'a failed avatar reload does not turn a saved upload into a failure',
    () async {
      final container = makeContainer(
        avatarFile: (final ref) async => throw const NetworkFailure(),
      );

      final result = await container
          .read(avatarUploadProvider.notifier)
          .upload(File('a.jpg'));

      expect(result.isSuccess, isTrue);
      expect(container.read(avatarUploadProvider), isNull);
    },
  );

  test('an own photo is uploaded as the avatar', () async {
    final container = makeContainer();

    await container.read(avatarUploadProvider.notifier).upload(File('me.jpg'));

    expect(updateUserAvatar.calls.single.path, 'me.jpg');
  });

  test('a preset is uploaded as the avatar', () async {
    final container = makeContainer();

    final result = await container
        .read(avatarUploadProvider.notifier)
        .applyPreset(PresetAvatar.male);

    expect(result.isSuccess, isTrue);
    expect(preparePresetAvatar.calls.single, PresetAvatar.male);
    expect(updateUserAvatar.calls.single.path, 'preset_male.jpg');
  });

  test('a preset that cannot be prepared uploads nothing', () async {
    final container = makeContainer();
    preparePresetAvatar.result = const Err(UnknownFailure());

    final result = await container
        .read(avatarUploadProvider.notifier)
        .applyPreset(PresetAvatar.male);

    expect(result.getError(), const UnknownFailure());
    expect(updateUserAvatar.calls, isEmpty);
  });

  test('rejects a second replacement while one is in flight', () async {
    final container = makeContainer();
    updateUserAvatar.pending = Completer();
    final notifier = container.read(avatarUploadProvider.notifier);

    final first = notifier.upload(File('me.jpg'));
    await Future<void>.delayed(Duration.zero);
    final second = await notifier.applyPreset(PresetAvatar.female);

    expect(second.getError(), isA<ValidationFailure>());
    expect(preparePresetAvatar.calls, isEmpty);

    updateUserAvatar.pending!.complete(const Ok(null));
    expect((await first).isSuccess, isTrue);
    expect(container.read(avatarUploadProvider), isNull);
  });

  test('exposes the photo being uploaded until it is in place', () async {
    final container = makeContainer();
    updateUserAvatar.pending = Completer();

    final applying = container
        .read(avatarUploadProvider.notifier)
        .applyPreset(PresetAvatar.male);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(avatarUploadProvider)?.path, 'preset_male.jpg');

    updateUserAvatar.pending!.complete(const Ok(null));
    await applying;
    expect(container.read(avatarUploadProvider), isNull);
  });
}
